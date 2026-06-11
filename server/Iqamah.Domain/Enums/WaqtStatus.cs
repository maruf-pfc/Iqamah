namespace Iqamah.Domain.Enums;

/// <summary>
/// Describes the punctuality of a prayer relative to its Waqt (time window).
/// Based on classical Fiqh categorisation — only applicable when a prayer IS offered.
/// </summary>
public enum WaqtStatus
{
    /// <summary>
    /// Awwal al-Waqt (أوّل الوقت) — "First of the time".
    /// Prayer offered within 15-20 minutes of the Adhan. Highest merit.
    /// </summary>
    AwwalAlWaqt = 0,

    /// <summary>
    /// Wast al-Waqt (وسط الوقت) — "Middle of the time".
    /// Prayer offered in the middle portion of its Waqt window.
    /// </summary>
    WastAlWaqt = 1,

    /// <summary>
    /// Akhir al-Waqt (آخر الوقت) — "End of the time".
    /// Prayer offered near expiry of the Waqt window. Still Ada' (on-time), reduced reward.
    /// </summary>
    AkhirAlWaqt = 2
}
