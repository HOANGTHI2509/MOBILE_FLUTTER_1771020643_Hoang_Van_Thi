# Sử dụng SDK để build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy csproj và restore dependencies
COPY ["PcmBackend.csproj", "./"]
RUN dotnet restore "PcmBackend.csproj"

# Copy toàn bộ source code
COPY . .
RUN dotnet publish "PcmBackend.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000
ENTRYPOINT ["dotnet", "PcmBackend.dll"]
