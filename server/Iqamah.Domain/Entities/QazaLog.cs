using Iqamah.Domain.Enums;
using Iqamah.Domain.Events;
using Iqamah.Domain.Exceptions;

namespace Iqamah.Domain.Entities;

/// <summary>
/// Represents a single Qaza (قضاء) obligation — a make-up prayer debt.
/// Created automatically by the state machine when <see cref="PrayerLog.RequiresQaza()"/> is true.
/// <para>
/// State machine: <see cref="QazaState.Pending"/> → <see cref="QazaState.Offered"/> (terminal).
/// </para>
/// </summary>
public sealed class QazaLog
{
    // ── Identity ─────────────────────────────────────────────────────────────
    public Guid Id { get; private set; }
    public Guid PrayerLogId { get; private set; }
    public int UserId { get; private set; }

    // ── Prayer Reference ──────────────────────────────────────────────────────
    public PrayerName PrayerName { get; private set; }
    public DateOnly OriginalPrayerDate { get; private set; }

    // ── State Machine ─────────────────────────────────────────────────────────
    public QazaState State { get; private set; }

    // ── Audit / Resolution ────────────────────────────────────────────────────
    public DateTime CreatedAt { get; private set; }

    /// <summary>UTC timestamp when the Qaza was fulfilled. Null while <see cref="State"/> is <see cref="QazaState.Pending"/>.</summary>
    public DateTime? FulfilledAt { get; private set; }

    /// <summary>
    /// Duration between incurring the Qaza debt and fulfilling it.
    /// Null while pending. Stored in database as an interval (ticks).
    /// </summary>
    public TimeSpan? TimeToResolution { get; private set; }

    // ── Navigation ────────────────────────────────────────────────────────────
    public PrayerLog PrayerLog { get; private set; } = null!;

    // ── Domain Events ─────────────────────────────────────────────────────────
    private readonly List<object> _domainEvents = [];
    public IReadOnlyList<object> DomainEvents => _domainEvents.AsReadOnly();
    public void ClearDomainEvents() => _domainEvents.Clear();

    // ── EF Core constructor ───────────────────────────────────────────────────
    private QazaLog() { }

    // ── Factory Method ────────────────────────────────────────────────────────
    /// <summary>
    /// Creates a new <see cref="QazaLog"/> in the <see cref="QazaState.Pending"/> state.
    /// Called by the Application layer after handling <see cref="PrayerMissedDomainEvent"/>.
    /// </summary>
    public static QazaLog CreatePending(
        Guid prayerLogId,
        int userId,
        PrayerName prayerName,
        DateOnly originalPrayerDate)
    {
        return new QazaLog
        {
            Id = Guid.NewGuid(),
            PrayerLogId = prayerLogId,
            UserId = userId,
            PrayerName = prayerName,
            OriginalPrayerDate = originalPrayerDate,
            State = QazaState.Pending,
            CreatedAt = DateTime.UtcNow
        };
    }

    // ── State Transition ──────────────────────────────────────────────────────

    /// <summary>
    /// Transitions this Qaza from <see cref="QazaState.Pending"/> to <see cref="QazaState.Offered"/>.
    /// Records <see cref="FulfilledAt"/> and computes <see cref="TimeToResolution"/>.
    /// Raises <see cref="QazaFulfilledDomainEvent"/>.
    /// </summary>
    /// <exception cref="DomainException">Thrown if already in the <see cref="QazaState.Offered"/> state.</exception>
    public void Fulfill()
    {
        if (State == QazaState.Offered)
            throw new DomainException(
                $"QazaLog {Id} has already been fulfilled and cannot be transitioned again.");

        FulfilledAt = DateTime.UtcNow;
        TimeToResolution = FulfilledAt.Value - CreatedAt;
        State = QazaState.Offered;

        _domainEvents.Add(new QazaFulfilledDomainEvent(
            Id, UserId, PrayerName, TimeToResolution.Value));
    }

    // ── Queries ───────────────────────────────────────────────────────────────

    /// <summary>Whether the obligation is still outstanding.</summary>
    public bool IsPending => State == QazaState.Pending;

    /// <summary>Whether the obligation has been discharged.</summary>
    public bool IsFulfilled => State == QazaState.Offered;
}
