using Iqamah.Domain.Interfaces.Repositories;
using Iqamah.Infrastructure.Auth;
using Iqamah.Infrastructure.Data;
using Iqamah.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Iqamah.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");

        services.AddDbContext<AppDbContext>((sp, options) =>
        {
            options.UseNpgsql(connectionString, npgsqlOptions =>
            {
                npgsqlOptions.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName);
            });
        });

        services.AddScoped<IPrayerLogRepository, PrayerLogRepository>();
        services.AddScoped<IQazaLogRepository, QazaLogRepository>();
        services.AddScoped<IUserRepository, UserRepository>();

        services.Configure<JwtOptions>(options =>
        {
            var section = configuration.GetSection("Jwt");
            options.Issuer = section["Issuer"] ?? string.Empty;
            options.Audience = section["Audience"] ?? string.Empty;
            options.SecretKey = section["SecretKey"] ?? string.Empty;
        });
        services.AddScoped<Application.Common.Interfaces.IJwtProvider, Auth.JwtProvider>();

        services.AddMemoryCache();
        services.AddHttpClient<Application.Common.Interfaces.IPrayerTimeService, Services.PrayerTimeService>();

        return services;
    }
}
