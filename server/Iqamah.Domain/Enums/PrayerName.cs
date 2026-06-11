namespace Iqamah.Domain.Enums;

/// <summary>
/// The five obligatory daily prayers (Salawat al-Khams).
/// </summary>
public enum PrayerName
{
    /// <summary>Dawn prayer — before sunrise.</summary>
    Fajr = 0,

    /// <summary>Midday prayer — after the sun passes its zenith.</summary>
    Dhuhr = 1,

    /// <summary>Afternoon prayer — in the late afternoon.</summary>
    Asr = 2,

    /// <summary>Sunset prayer — just after sunset.</summary>
    Maghrib = 3,

    /// <summary>Night prayer — after darkness has set in.</summary>
    Isha = 4
}
