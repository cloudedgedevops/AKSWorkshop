
# https://hub.docker.com/_/microsoft-dotnet
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /source

# copy csproj and restore as distinct layers
COPY aspnetapp/*.csproj .
RUN dotnet restore --use-current-runtime  

# copy everything else and build app
COPY aspnetapp/. .
RUN dotnet publish -c Release -o /app --use-current-runtime --self-contained false --no-restore

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:7.0
RUN adduser --uid 8877 appuser
WORKDIR /app
COPY --from=build /app .
RUN chmod -R 447 /app
USER appuser
ENTRYPOINT ["dotnet", "aspnetapp.dll"]
