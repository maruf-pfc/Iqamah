using Iqamah.Domain.Enums;
using Iqamah.Domain.Events;
using Iqamah.Domain.Exceptions;

namespace Iqamah.Domain.Entities;

/// <summary>
/// Aggregate root representing a single prayer (Salah) record for one Waqt on one day.
/// <para>
/// Business rules enforced here (DDD Rich Model):
/// <list type="bullet">
///   <item>An offered prayer requires a <see cref="WaqtStatus"/>; a missed prayer requires a <see cref="MissedReason"/>.</item>
///   <item><c>IsJummah</c> is only valid for <see cref="PrayerName.Dhuhr"/>.</item>
///   <item><c>IsJamaah</c> cannot be true when <c>IsTraveling</c> is true (typically).</item>
///   <item>A missed prayer automatically raises <see cref="PrayerMissedDomainEvent"/> unless the reason is <see cref="MissedReason.ExcusedImpurity"/>.</item>
/// </list>
/// </para>
/// </summary>
public sealed class PrayerLog
{
    // ── Identity ─────────────────────────────────────────────────────────────
    public Guid Id { get; private set; }
    public int UserId { get; private set; }

    // ── Core Prayer Data ──────────────────────────────────────────────────────
    public PrayerName PrayerName { get; private set; }
    public DateOnly PrayerDate { get; private set; }

    // ── Offer / Miss ──────────────────────────────────────────────────────────
    /// <summary>True when the prayer was performed in its Waqt (Ada').</summary>
    public bool IsOffered { get; private set; }

    /// <summary>Non-null only when <see cref="IsOffered"/> is <c>true</c>.</summary>
    public WaqtStatus? WaqtStatus { get; private set; }

    /// <summary>Non-null only when <see cref="IsOffered"/> is <c>false</c>.</summary>
    public MissedReason? MissedReason { get; private set; }

    // ── Modifiers ─────────────────────────────────────────────────────────────
    /// <summary>Prayer performed in congregation (Jamaah). Increases reward 27×.</summary>
    public bool IsJamaah { get; private set; }

    /// <summary>User was a traveller (Musafir), enabling Qasr/Jam' dispensations.</summary>
    public bool IsTraveling { get; private set; }

    /// <summary>Friday Jumu'ah prayer replaces Dhuhr. Only valid for <see cref="PrayerName.Dhuhr"/>.</summary>
    public bool IsJummah { get; private set; }

    /// <summary>Prayer performed at home instead of the mosque.</summary>
    public bool IsHome { get; private set; }

    /// <summary>Notes on Quran pages, ayats, or surah read after or during this prayer window.</summary>
    public string? QuranNotes { get; private set; }

    /// <summary>Tracks whether Tasbih was performed after this prayer.</summary>
    public bool HasTasbih { get; private set; }

    // ── Audit ─────────────────────────────────────────────────────────────────
    public DateTime LoggedAt { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    // ── Navigation ────────────────────────────────────────────────────────────
    public QazaLog? QazaLog { get; private set; }

    // ── Domain Events ─────────────────────────────────────────────────────────
    private readonly List<object> _domainEvents = [];
    public IReadOnlyList<object> DomainEvents => _domainEvents.AsReadOnly();
    public void ClearDomainEvents() => _domainEvents.Clear();

    // ── EF Core constructor ───────────────────────────────────────────────────
    private PrayerLog() { }

    // ── Factory Method ────────────────────────────────────────────────────────
    /// <summary>
    /// Creates and validates a new <see cref="PrayerLog"/> instance.
    /// Raises <see cref="PrayerMissedDomainEvent"/> when applicable.
    /// </summary>
    public static PrayerLog Create(
        int userId,
        PrayerName prayerName,
        DateOnly prayerDate,
        bool isOffered,
        WaqtStatus? waqtStatus = null,
        MissedReason? missedReason = null,
        bool isJamaah = false,
        bool isTraveling = false,
        bool isJummah = false,
        bool isHome = false,
        string? quranNotes = null,
        bool hasTasbih = false)
    {
        // ── Invariant checks ──────────────────────────────────────────────────
        if (isOffered && waqtStatus is null)
            throw new DomainException("WaqtStatus is required when a prayer is offered.");

        if (!isOffered && missedReason is null)
            throw new DomainException("MissedReason is required when a prayer is missed.");

        if (isOffered && missedReason is not null)
            throw new DomainException("MissedReason must not be set when a prayer is offered.");

        if (!isOffered && waqtStatus is not null)
            throw new DomainException("WaqtStatus must not be set when a prayer is missed.");

        if (isJummah && prayerName != PrayerName.Dhuhr)
            throw new DomainException("IsJummah is only applicable to the Dhuhr prayer.");

        var log = new PrayerLog
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            PrayerName = prayerName,
            PrayerDate = prayerDate,
            IsOffered = isOffered,
            WaqtStatus = waqtStatus,
            MissedReason = missedReason,
            IsJamaah = isJamaah,
            IsTraveling = isTraveling,
            IsJummah = isJummah,
            IsHome = isHome,
            QuranNotes = quranNotes,
            HasTasbih = hasTasbih,
            LoggedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // ── State machine: raise Qaza event if applicable ─────────────────────
        if (log.RequiresQaza())
        {
            log._domainEvents.Add(new PrayerMissedDomainEvent(
                log.Id, userId, prayerName, prayerDate, missedReason!.Value));
        }

        return log;
    }

    // ── Domain Behaviour ─────────────────────────────────────────────────────

    /// <summary>
    /// Returns <c>true</c> if this prayer log incurs a Qaza obligation.
    /// Rule: missed AND reason is NOT <see cref="MissedReason.ExcusedImpurity"/>.
    /// </summary>
    public bool RequiresQaza() =>
        !IsOffered && MissedReason != Enums.MissedReason.ExcusedImpurity;

    /// <summary>
    /// Returns <c>true</c> if the missed reason is classified as excused (Ma'dhur) — no sin.
    /// </summary>
    public bool IsExcusedAbsence() =>
        !IsOffered &&
        MissedReason is Enums.MissedReason.ExcusedImpurity
            or Enums.MissedReason.ExcusedSleep
            or Enums.MissedReason.ExcusedForgetfulness;

    /// <summary>Links the generated <see cref="QazaLog"/> after it has been persisted.</summary>
    internal void AttachQazaLog(QazaLog qazaLog) => QazaLog = qazaLog;

    /// <summary>
    /// Updates the prayer log parameters and enforces domain invariants.
    /// Raises domain events if state transitions necessitate a new Qaza.
    /// </summary>
    public void Update(
        bool isOffered,
        WaqtStatus? waqtStatus = null,
        MissedReason? missedReason = null,
        bool isJamaah = false,
        bool isTraveling = false,
        bool isJummah = false,
        bool isHome = false,
        string? quranNotes = null,
        bool hasTasbih = false)
    {
        // ── Invariant checks ──────────────────────────────────────────────────
        if (isOffered && waqtStatus is null)
            throw new DomainException("WaqtStatus is required when a prayer is offered.");

        if (!isOffered && missedReason is null)
            throw new DomainException("MissedReason is required when a prayer is missed.");

        if (isOffered && missedReason is not null)
            throw new DomainException("MissedReason must not be set when a prayer is offered.");

        if (!isOffered && waqtStatus is not null)
            throw new DomainException("WaqtStatus must not be set when a prayer is missed.");

        if (isJummah && PrayerName != PrayerName.Dhuhr)
            throw new DomainException("IsJummah is only applicable to the Dhuhr prayer.");

        var wasRequiringQaza = RequiresQaza();

        IsOffered = isOffered;
        WaqtStatus = waqtStatus;
        MissedReason = missedReason;
        IsJamaah = isJamaah;
        IsTraveling = isTraveling;
        IsJummah = isJummah;
        IsHome = isHome;
        QuranNotes = quranNotes;
        HasTasbih = hasTasbih;
        UpdatedAt = DateTime.UtcNow;

        var isNowRequiringQaza = RequiresQaza();

        // If it transitioned from not requiring Qaza to requiring Qaza
        if (isNowRequiringQaza && !wasRequiringQaza)
        {
            _domainEvents.Add(new PrayerMissedDomainEvent(
                Id, UserId, PrayerName, PrayerDate, missedReason!.Value));
        }
    }
}
