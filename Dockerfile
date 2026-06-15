# Stage 1: Build the Vue SPA frontend
FROM oven/bun:latest AS client-build
WORKDIR /src
COPY client/package.json client/bun.lock ./
RUN bun install --frozen-lockfile
COPY client/ ./
RUN bun run build

# Stage 2: Build the .NET 10 API backend
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS server-build
WORKDIR /app

# Copy csproj and slnx files to restore dependencies
COPY server/Iqamah.slnx ./
COPY server/Iqamah.API/Iqamah.API.csproj ./Iqamah.API/
COPY server/Iqamah.Application/Iqamah.Application.csproj ./Iqamah.Application/
COPY server/Iqamah.Domain/Iqamah.Domain.csproj ./Iqamah.Domain/
COPY server/Iqamah.Infrastructure/Iqamah.Infrastructure.csproj ./Iqamah.Infrastructure/
COPY server/Iqamah.Tests.Unit/Iqamah.Tests.Unit.csproj ./Iqamah.Tests.Unit/

# Restore dependencies
RUN dotnet restore Iqamah.API/Iqamah.API.csproj

# Copy the rest of the source code
COPY server/ ./

# Copy client build output into Iqamah.API's wwwroot folder
COPY --from=client-build /src/dist ./Iqamah.API/wwwroot

# Build and publish release
RUN dotnet publish Iqamah.API/Iqamah.API.csproj -c Release -o out

# Stage 3: Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=server-build /app/out .

# Expose default ASP.NET Core port
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "Iqamah.API.dll"]
