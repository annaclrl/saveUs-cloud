param(
    [string]$ResourceGroup = "rg-saveus-paas",
    [string]$Regiao = "canadacentral",
    [Parameter(Mandatory)][string]$AcrNome,
    [string]$PlanoNome = "plano-saveus-paas",
    [string]$Sku = "B1",
    [Parameter(Mandatory)][string]$WebAppNome,
    [string]$ImagemNome = "saveus-api",
    [string]$ArquivoEnv = ".env"
)
$ErrorActionPreference = "Stop"
$raiz = Split-Path $PSScriptRoot -Parent

az group create --name $ResourceGroup --location $Regiao --tags projeto=saveus --output none

az acr create --resource-group $ResourceGroup --name $AcrNome --sku Basic `
    --admin-enabled true --tags projeto=saveus --output none

az appservice plan create --resource-group $ResourceGroup --name $PlanoNome `
    --location $Regiao --is-linux --sku $Sku --tags projeto=saveus --output none

$acrLoginServer = az acr show --name $AcrNome --query loginServer -o tsv
$acrUsuario = az acr credential show --name $AcrNome --query username -o tsv
$acrSenha = az acr credential show --name $AcrNome --query "passwords[0].value" -o tsv

az webapp create --resource-group $ResourceGroup --plan $PlanoNome --name $WebAppNome `
    --deployment-container-image-name "$acrLoginServer/${ImagemNome}:latest" --output none

az webapp config container set --resource-group $ResourceGroup --name $WebAppNome `
    --docker-custom-image-name "$acrLoginServer/${ImagemNome}:latest" `
    --docker-registry-server-url "https://$acrLoginServer" `
    --docker-registry-server-user $acrUsuario `
    --docker-registry-server-password $acrSenha --output none

$local = Get-Content (Join-Path $raiz $ArquivoEnv)
function Ler($chave) { ($local | Where-Object { $_ -match "^$chave=" }) -replace "^$chave=", "" }

$bytes = New-Object byte[] 48
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$jwtChave = [Convert]::ToBase64String($bytes)

az webapp config appsettings set --resource-group $ResourceGroup --name $WebAppNome --settings `
    "WEBSITES_PORT=8080" `
    "ASPNETCORE_ENVIRONMENT=Production" `
    "Database__AplicarMigracoesAoIniciar=true" `
    "ConnectionStrings__Refugio=User Id=$(Ler 'ORACLE_USUARIO');Password=$(Ler 'ORACLE_SENHA');Data Source=$(Ler 'ORACLE_DATA_SOURCE')" `
    "Jwt__Chave=$jwtChave" `
    "Seed__SenhaUsuarios=$(Ler 'SEED_SENHA_USUARIOS')" --output none

Write-Host "ACR:      $acrLoginServer (usuario do Service Connection 'conexao-acr-saveus': $acrUsuario)"
Write-Host "Web App:  https://$WebAppNome.azurewebsites.net/swagger"
Write-Host "O app só fica saudável depois que a pipeline de Build publicar a imagem '$ImagemNome:latest' no ACR."
