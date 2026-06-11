using Iqamah.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iqamah.Infrastructure.Data.Configurations;

public sealed class QazaLogConfiguration : IEntityTypeConfiguration<QazaLog>
{
    public void Configure(EntityTypeBuilder<QazaLog> builder)
    {
        builder.ToTable("QazaLogs");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.UserId)
            .IsRequired();

        builder.Property(x => x.PrayerName)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(x => x.OriginalPrayerDate)
            .IsRequired();

        builder.Property(x => x.State)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(x => x.CreatedAt)
            .IsRequired();

        builder.Property(x => x.FulfilledAt)
            .IsRequired(false);

        builder.Property(x => x.TimeToResolution)
            .IsRequired(false);

        // Optimized indexing on state and userId
        builder.HasIndex(x => new { x.UserId, x.State });
        builder.HasIndex(x => new { x.UserId, x.PrayerName, x.State });
    }
}
