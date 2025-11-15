# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY FrontendApi.csproj ./
RUN dotnet restore "FrontendApi.csproj"

# Copy everything else and build
COPY . ./
RUN dotnet build "FrontendApi.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "FrontendApi.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "FrontendApi.dll"]
