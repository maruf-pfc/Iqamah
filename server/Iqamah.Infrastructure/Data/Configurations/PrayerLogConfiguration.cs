using Iqamah.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iqamah.Infrastructure.Data.Configurations;

public sealed class PrayerLogConfiguration : IEntityTypeConfiguration<PrayerLog>
{
    public void Configure(EntityTypeBuilder<PrayerLog> builder)
    {
        builder.ToTable("PrayerLogs");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.UserId)
            .IsRequired();

        builder.Property(x => x.PrayerName)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(x => x.PrayerDate)
            .IsRequired();

        builder.Property(x => x.IsOffered)
            .IsRequired();

        builder.Property(x => x.WaqtStatus)
            .HasConversion<int>()
            .IsRequired(false);

        builder.Property(x => x.MissedReason)
            .HasConversion<int>()
            .IsRequired(false);

        builder.Property(x => x.IsJamaah)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(x => x.IsTraveling)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(x => x.IsJummah)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(x => x.LoggedAt)
            .IsRequired();

        builder.Property(x => x.UpdatedAt)
            .IsRequired();

        // One-to-one relationship: PrayerLog has one QazaLog, QazaLog belongs to one PrayerLog
        builder.HasOne(x => x.QazaLog)
            .WithOne(x => x.PrayerLog)
            .HasForeignKey<QazaLog>(x => x.PrayerLogId)
            .OnDelete(DeleteBehavior.Cascade);

        // Optimized indexing on date, userId and prayer name
        builder.HasIndex(x => new { x.UserId, x.PrayerDate });
        builder.HasIndex(x => new { x.UserId, x.PrayerName, x.PrayerDate }).IsUnique();
    }
}
