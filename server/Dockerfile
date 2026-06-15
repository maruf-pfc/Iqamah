# Stage 1: Build the .NET 10 API backend
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

# Copy csproj and slnx files to restore dependencies
COPY Iqamah.slnx ./
COPY Iqamah.API/Iqamah.API.csproj ./Iqamah.API/
COPY Iqamah.Application/Iqamah.Application.csproj ./Iqamah.Application/
COPY Iqamah.Domain/Iqamah.Domain.csproj ./Iqamah.Domain/
COPY Iqamah.Infrastructure/Iqamah.Infrastructure.csproj ./Iqamah.Infrastructure/
COPY Iqamah.Tests.Unit/Iqamah.Tests.Unit.csproj ./Iqamah.Tests.Unit/

# Restore dependencies
RUN dotnet restore Iqamah.API/Iqamah.API.csproj

# Copy the rest of the source code
COPY . ./

# Build and publish release
RUN dotnet publish Iqamah.API/Iqamah.API.csproj -c Release -o out

# Stage 2: Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/out .

# Expose default ASP.NET Core port
EXPOSE 5229
ENV ASPNETCORE_URLS=http://+:5229
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "Iqamah.API.dll"]
