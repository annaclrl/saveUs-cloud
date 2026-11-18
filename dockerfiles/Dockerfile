FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/SaveUs.Api/SaveUs.Api.csproj src/SaveUs.Api/
COPY src/SaveUs.Application/SaveUs.Application.csproj src/SaveUs.Application/
COPY src/SaveUs.Domain/SaveUs.Domain.csproj src/SaveUs.Domain/
COPY src/SaveUs.Infrastructure/SaveUs.Infrastructure.csproj src/SaveUs.Infrastructure/
RUN dotnet restore src/SaveUs.Api/SaveUs.Api.csproj

COPY src/ src/
RUN dotnet publish src/SaveUs.Api/SaveUs.Api.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
USER $APP_UID

ENTRYPOINT ["dotnet", "SaveUs.Api.dll"]
