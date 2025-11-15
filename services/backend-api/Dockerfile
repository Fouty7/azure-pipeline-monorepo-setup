# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY BackendApi.csproj ./
RUN dotnet restore "BackendApi.csproj"

# Copy everything else and build
COPY . ./
RUN dotnet build "BackendApi.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "BackendApi.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "BackendApi.dll"]
