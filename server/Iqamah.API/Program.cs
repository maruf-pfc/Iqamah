using System.Text;
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using Iqamah.API.Middleware;
using Iqamah.Application;
using Iqamah.Infrastructure;
using Iqamah.Infrastructure.Auth;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;

// Load environment variables from .env file if it exists
var currentDir = Directory.GetCurrentDirectory();
var pathsToTry = new[]
{
    Path.Combine(currentDir, ".env"),
    Path.Combine(currentDir, "Iqamah.API", ".env"),
    Path.Combine(currentDir, "..", ".env"),
    Path.Combine(AppContext.BaseDirectory, ".env")
};

foreach (var path in pathsToTry)
{
    if (File.Exists(path))
    {
        foreach (var line in File.ReadAllLines(path))
        {
            if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#')) continue;
            var parts = line.Split('=', 2);
            if (parts.Length == 2)
            {
                var key = parts[0].Trim();
                var value = parts[1].Trim().Trim('"').Trim('\'');
                Environment.SetEnvironmentVariable(key, value);
            }
        }
        break; // Stop at first .env file found
    }
}

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Serialize enums as string values in JSON for API readability
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowClient", policy =>
    {
        var origins = new List<string> { "http://localhost:5173", "http://localhost:3000" };
        var clientUrl = Environment.GetEnvironmentVariable("CLIENT_URL");
        if (!string.IsNullOrEmpty(clientUrl))
        {
            origins.AddRange(clientUrl.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
        }

        policy.WithOrigins(origins.ToArray())
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Register Clean Architecture Layers
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration);

// Configure JWT Authentication
var jwtOptionsSection = builder.Configuration.GetSection("Jwt");
builder.Services.Configure<JwtOptions>(jwtOptionsSection);
var jwtOptions = jwtOptionsSection.Get<JwtOptions>();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtOptions?.Issuer ?? throw new InvalidOperationException("JWT Issuer is missing from configuration."),
            ValidAudience = jwtOptions?.Audience ?? throw new InvalidOperationException("JWT Audience is missing from configuration."),
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtOptions?.SecretKey ?? throw new InvalidOperationException("JWT SecretKey is missing from configuration.")))
        };
    });

builder.Services.AddAuthorization();

// Configure Rate Limiting
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? httpContext.Request.Headers.Host.ToString();
        return RateLimitPartition.GetFixedWindowLimiter(ip, _ => new FixedWindowRateLimiterOptions
        {
            AutoReplenishment = true,
            PermitLimit = 60,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });
});

// Global Exception Handler using modern IExceptionHandler
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Global Exception Handling Middleware
app.UseExceptionHandler();

app.UseCors("AllowClient");

app.UseHttpsRedirection();

app.UseDefaultFiles();
app.UseStaticFiles();

app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health").DisableRateLimiting();
app.MapFallbackToFile("index.html");

app.Run();
