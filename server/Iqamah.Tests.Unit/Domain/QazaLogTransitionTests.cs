using FluentAssertions;
using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Events;
using Iqamah.Domain.Exceptions;

namespace Iqamah.Tests.Unit.Domain;

/// <summary>
/// Tests for the <see cref="QazaLog"/> state machine — Pending → Offered transition.
/// </summary>
public sealed class QazaLogTransitionTests
{
    private static readonly DateOnly OriginalDate = new(2025, 1, 1);
    private const int UserId = 7;

    private static QazaLog MakePending() =>
        QazaLog.CreatePending(Guid.NewGuid(), UserId, PrayerName.Fajr, OriginalDate);

    // ─────────────────────────────────────────────────────────────────────────
    // Factory
    // ─────────────────────────────────────────────────────────────────────────

    [Fact]
    public void CreatePending_SetsCorrectInitialState()
    {
        var prayerLogId = Guid.NewGuid();
        var qaza = QazaLog.CreatePending(prayerLogId, UserId, PrayerName.Isha, OriginalDate);

        qaza.State.Should().Be(QazaState.Pending);
        qaza.IsPending.Should().BeTrue();
        qaza.IsFulfilled.Should().BeFalse();
        qaza.FulfilledAt.Should().BeNull();
        qaza.TimeToResolution.Should().BeNull();
        qaza.PrayerLogId.Should().Be(prayerLogId);
        qaza.UserId.Should().Be(UserId);
        qaza.PrayerName.Should().Be(PrayerName.Isha);
        qaza.OriginalPrayerDate.Should().Be(OriginalDate);
        qaza.Id.Should().NotBeEmpty();
        qaza.DomainEvents.Should().BeEmpty();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Fulfill transition
    // ─────────────────────────────────────────────────────────────────────────

    [Fact]
    public void Fulfill_TransitionsFromPendingToOffered()
    {
        var qaza = MakePending();

        qaza.Fulfill();

        qaza.State.Should().Be(QazaState.Offered);
        qaza.IsFulfilled.Should().BeTrue();
        qaza.IsPending.Should().BeFalse();
    }

    [Fact]
    public void Fulfill_SetsTimestampsAndResolutionDuration()
    {
        var qaza = MakePending();
        var before = DateTime.UtcNow;

        qaza.Fulfill();

        var after = DateTime.UtcNow;

        qaza.FulfilledAt.Should().NotBeNull()
            .And.BeOnOrAfter(before)
            .And.BeOnOrBefore(after);

        qaza.TimeToResolution.Should().NotBeNull()
            .And.BeGreaterThanOrEqualTo(TimeSpan.Zero);
    }

    [Fact]
    public void Fulfill_RaisesQazaFulfilledDomainEvent()
    {
        var qaza = MakePending();

        qaza.Fulfill();

        qaza.DomainEvents.Should().ContainSingle()
            .Which.Should().BeOfType<QazaFulfilledDomainEvent>();

        var evt = (QazaFulfilledDomainEvent)qaza.DomainEvents[0];
        evt.QazaLogId.Should().Be(qaza.Id);
        evt.UserId.Should().Be(UserId);
        evt.PrayerName.Should().Be(PrayerName.Fajr);
        evt.TimeToResolution.Should().Be(qaza.TimeToResolution!.Value);
    }

    [Fact]
    public void Fulfill_WhenAlreadyOffered_ThrowsDomainException()
    {
        var qaza = MakePending();
        qaza.Fulfill();

        var act = () => qaza.Fulfill();

        act.Should().Throw<DomainException>()
            .WithMessage("*already been fulfilled*");
    }

    [Fact]
    public void Fulfill_ClearDomainEvents_RemovesEvent()
    {
        var qaza = MakePending();
        qaza.Fulfill();

        qaza.ClearDomainEvents();

        qaza.DomainEvents.Should().BeEmpty();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Integration with PrayerLog state machine
    // ─────────────────────────────────────────────────────────────────────────

    [Fact]
    public void QazaLog_CreatedFromPrayerMissedEvent_LinkedToCorrectPrayer()
    {
        // Simulate what the Application layer does after handling PrayerMissedDomainEvent
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var prayerLog = PrayerLog.Create(UserId, PrayerName.Asr, today,
            isOffered: false, missedReason: MissedReason.UnexcusedLaziness);

        var evt = prayerLog.DomainEvents
            .OfType<PrayerMissedDomainEvent>()
            .Single();

        var qaza = QazaLog.CreatePending(evt.PrayerLogId, evt.UserId,
            evt.PrayerName, evt.PrayerDate);

        qaza.PrayerLogId.Should().Be(prayerLog.Id);
        qaza.PrayerName.Should().Be(PrayerName.Asr);
        qaza.OriginalPrayerDate.Should().Be(today);
        qaza.State.Should().Be(QazaState.Pending);
    }
}
