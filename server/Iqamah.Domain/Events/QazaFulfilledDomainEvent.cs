using Iqamah.Domain.Enums;

namespace Iqamah.Domain.Events;

/// <summary>
/// Raised by <see cref="Entities.QazaLog"/> when a pending Qaza prayer is fulfilled.
/// Application handlers may use this for analytics aggregation.
/// </summary>
public sealed record QazaFulfilledDomainEvent(
    Guid QazaLogId,
    int UserId,
    PrayerName PrayerName,
    TimeSpan TimeToResolution);
