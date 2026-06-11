using Iqamah.Domain.Enums;

namespace Iqamah.Domain.Events;

/// <summary>
/// Raised by <see cref="Entities.PrayerLog"/> when a prayer is recorded as missed
/// and a Qaza obligation must be created.
/// Consumers in the Application layer handle this to create the <see cref="Entities.QazaLog"/>.
/// </summary>
public sealed record PrayerMissedDomainEvent(
    Guid PrayerLogId,
    int UserId,
    PrayerName PrayerName,
    DateOnly PrayerDate,
    MissedReason MissedReason);
