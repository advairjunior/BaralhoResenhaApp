# Mesma versão usada nos testes locais; trocar só junto com o Flutter local.
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS cliente
WORKDIR /src/cliente
COPY cliente/pubspec.yaml cliente/pubspec.lock ./
RUN flutter pub get
COPY cliente/ ./
RUN flutter build web --release

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS compilacao
WORKDIR /src
COPY servidor/BaralhoResenhaApp.Api/BaralhoResenhaApp.Api.csproj servidor/BaralhoResenhaApp.Api/
RUN dotnet restore servidor/BaralhoResenhaApp.Api/BaralhoResenhaApp.Api.csproj
COPY servidor/BaralhoResenhaApp.Api/ servidor/BaralhoResenhaApp.Api/
RUN dotnet publish servidor/BaralhoResenhaApp.Api/BaralhoResenhaApp.Api.csproj \
    --configuration Release --no-restore --output /app/publicar
COPY --from=cliente /src/cliente/build/web /app/publicar/wwwroot

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=compilacao /app/publicar ./
ENV ASPNETCORE_HTTP_PORTS=10000
EXPOSE 10000
ENTRYPOINT ["dotnet", "BaralhoResenhaApp.Api.dll"]
