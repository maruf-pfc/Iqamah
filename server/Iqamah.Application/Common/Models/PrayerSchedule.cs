using System;
using System.Collections.Generic;
using System.Linq;

namespace Iqamah.Application.Common.Models;

public class PrayerSchedule
{
    public required PrayerEntry Fajr { get; init; }
    public required PrayerEntry Dhuhr { get; init; }
    public required PrayerEntry Asr { get; init; }
    public required PrayerEntry Maghrib { get; init; }
    public required PrayerEntry Isha { get; init; }
    public required DateTime Sunrise { get; init; }
    public required List<ForbiddenZone> ForbiddenZones { get; init; }
    public string? HijriDate { get; init; }

    public bool IsAnyForbiddenNow => ForbiddenZones.Any(z => z.IsActive);

    public List<PrayerEntry> AllPrayers => new() { Fajr, Dhuhr, Asr, Maghrib, Isha };
}
