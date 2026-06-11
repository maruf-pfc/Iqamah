using Iqamah.Domain.Entities;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Iqamah.Infrastructure.Data;

public sealed class AppDbContext : DbContext
{
    private readonly IPublisher _publisher;

    public AppDbContext(DbContextOptions<AppDbContext> options, IPublisher publisher)
        : base(options)
    {
        _publisher = publisher;
    }

    public DbSet<PrayerLog> PrayerLogs => Set<PrayerLog>();
    public DbSet<QazaLog> QazaLogs => Set<QazaLog>();
    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // 1. Dispatch Domain Events before writing to database (or after, depending on transaction preference).
        // For our state machine, we want the events to run within the same database transaction.
        // Therefore, we publish events before save, letting event handlers add entities to the DbContext, 
        // and then save everything together in one atomic transaction!
        await DispatchDomainEventsAsync(cancellationToken);

        return await base.SaveChangesAsync(cancellationToken);
    }

    private async Task DispatchDomainEventsAsync(CancellationToken cancellationToken)
    {
        var domainEntities = ChangeTracker
            .Entries()
            .Where(x => x.Entity is PrayerLog or QazaLog)
            .ToList();

        // Extract events
        var domainEvents = new List<object>();
        foreach (var entry in domainEntities)
        {
            if (entry.Entity is PrayerLog prayerLog && prayerLog.DomainEvents.Any())
            {
                domainEvents.AddRange(prayerLog.DomainEvents);
                prayerLog.ClearDomainEvents();
            }
            else if (entry.Entity is QazaLog qazaLog && qazaLog.DomainEvents.Any())
            {
                domainEvents.AddRange(qazaLog.DomainEvents);
                qazaLog.ClearDomainEvents();
            }
        }

        // Publish events. Handlers will run and mutate the context if needed.
        foreach (var domainEvent in domainEvents)
        {
            await _publisher.Publish(domainEvent, cancellationToken);
        }
    }
}
