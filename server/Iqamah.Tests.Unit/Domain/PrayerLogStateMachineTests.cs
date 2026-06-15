using FluentAssertions;
using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Events;
using Iqamah.Domain.Exceptions;

namespace Iqamah.Tests.Unit.Domain;

/// <summary>
/// Tests for the <see cref="PrayerLog"/> state-machine and invariant rules.
/// </summary>
public sealed class PrayerLogStateMachineTests
{
    private static readonly DateOnly Today = DateOnly.FromDateTime(DateTime.UtcNow);
    private const int UserId = 42;

    // ─────────────────────────────────────────────────────────────────────────
    // Happy paths — offered prayer
    // ─────────────────────────────────────────────────────────────────────────

    [Theory]
    [InlineData(WaqtStatus.AwwalAlWaqt)]
    [InlineData(WaqtStatus.WastAlWaqt)]
    [InlineData(WaqtStatus.AkhirAlWaqt)]
    public void Create_OfferedPrayer_DoesNotRequireQaza(WaqtStatus status)
    {
        // Arrange & Act
        var log = PrayerLog.Create(UserId, PrayerName.Fajr, Today,
            isOffered: true, waqtStatus: status);

        // Assert
        log.RequiresQaza().Should().BeFalse();
        log.DomainEvents.Should().BeEmpty();
    }

    [Fact]
    public void Create_OfferedPrayer_SetsCorrectProperties()
    {
        var log = PrayerLog.Create(UserId, PrayerName.Asr, Today,
            isOffered: true, waqtStatus: WaqtStatus.AwwalAlWaqt,
            isJamaah: true, isTraveling: false);

        log.IsOffered.Should().BeTrue();
        log.WaqtStatus.Should().Be(WaqtStatus.AwwalAlWaqt);
        log.MissedReason.Should().BeNull();
        log.IsJamaah.Should().BeTrue();
        log.UserId.Should().Be(UserId);
        log.PrayerName.Should().Be(PrayerName.Asr);
        log.Id.Should().NotBeEmpty();
    }

    [Fact]
    public void Create_OfferedPrayer_WithIsHome_SetsCorrectProperties()
    {
        var log = PrayerLog.Create(UserId, PrayerName.Isha, Today,
            isOffered: true, waqtStatus: WaqtStatus.AwwalAlWaqt,
            isHome: true);

        log.IsHome.Should().BeTrue();
    }

    [Fact]
    public void Create_OfferedPrayer_WithQuranNotesAndTasbih_SetsCorrectProperties()
    {
        var log = PrayerLog.Create(UserId, PrayerName.Fajr, Today,
            isOffered: true, waqtStatus: WaqtStatus.AwwalAlWaqt,
            quranNotes: "Surah Al-Mulk", hasTasbih: true);

        log.QuranNotes.Should().Be("Surah Al-Mulk");
        log.HasTasbih.Should().BeTrue();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Qaza state-machine — missed prayer
    // ─────────────────────────────────────────────────────────────────────────

    [Fact]
    public void Create_MissedWithExcusedImpurity_DoesNotRequireQaza()
    {
        // ExcusedImpurity (Hayd/Nifas) is the ONLY reason that cancels the obligation.
        var log = PrayerLog.Create(UserId, PrayerName.Dhuhr, Today,
            isOffered: false, missedReason: MissedReason.ExcusedImpurity);

        log.RequiresQaza().Should().BeFalse();
        log.DomainEvents.Should().BeEmpty(
            "no Qaza event should be raised for ExcusedImpurity");
    }

    [Theory]
    [InlineData(MissedReason.ExcusedSleep)]
    [InlineData(MissedReason.ExcusedForgetfulness)]
    [InlineData(MissedReason.UnexcusedSituational)]
    [InlineData(MissedReason.UnexcusedLaziness)]
    [InlineData(MissedReason.UnexcusedDistraction)]
    public void Create_MissedWithAnyOtherReason_RequiresQaza_AndRaisesEvent(MissedReason reason)
    {
        var log = PrayerLog.Create(UserId, PrayerName.Fajr, Today,
            isOffered: false, missedReason: reason);

        log.RequiresQaza().Should().BeTrue(
            $"{reason} should still incur a Qaza obligation");

        log.DomainEvents.Should().ContainSingle()
            .Which.Should().BeOfType<PrayerMissedDomainEvent>();

        var evt = (PrayerMissedDomainEvent)log.DomainEvents[0];
        evt.UserId.Should().Be(UserId);
        evt.PrayerName.Should().Be(PrayerName.Fajr);
        evt.MissedReason.Should().Be(reason);
        evt.PrayerLogId.Should().Be(log.Id);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // IsExcusedAbsence helper
    // ─────────────────────────────────────────────────────────────────────────

    [Theory]
    [InlineData(MissedReason.ExcusedImpurity, true)]
    [InlineData(MissedReason.ExcusedSleep, true)]
    [InlineData(MissedReason.ExcusedForgetfulness, true)]
    [InlineData(MissedReason.UnexcusedSituational, false)]
    [InlineData(MissedReason.UnexcusedLaziness, false)]
    [InlineData(MissedReason.UnexcusedDistraction, false)]
    public void IsExcusedAbsence_ReturnsCorrectClassification(
        MissedReason reason, bool expectedExcused)
    {
        var log = PrayerLog.Create(UserId, PrayerName.Isha, Today,
            isOffered: false, missedReason: reason);

        log.IsExcusedAbsence().Should().Be(expectedExcused);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Invariant violations
    // ─────────────────────────────────────────────────────────────────────────

    [Fact]
    public void Create_OfferedWithoutWaqtStatus_ThrowsDomainException()
    {
        var act = () => PrayerLog.Create(UserId, PrayerName.Fajr, Today, isOffered: true);

        act.Should().Throw<DomainException>()
            .WithMessage("*WaqtStatus*");
    }

    [Fact]
    public void Create_MissedWithoutMissedReason_ThrowsDomainException()
    {
        var act = () => PrayerLog.Create(UserId, PrayerName.Fajr, Today, isOffered: false);

        act.Should().Throw<DomainException>()
            .WithMessage("*MissedReason*");
    }

    [Fact]
    public void Create_OfferedWithMissedReason_ThrowsDomainException()
    {
        var act = () => PrayerLog.Create(UserId, PrayerName.Fajr, Today,
            isOffered: true,
            waqtStatus: WaqtStatus.WastAlWaqt,
            missedReason: MissedReason.UnexcusedLaziness);

        act.Should().Throw<DomainException>()
            .WithMessage("*MissedReason must not be set*");
    }

    [Fact]
    public void Create_MissedWithWaqtStatus_ThrowsDomainException()
    {
        var act = () => PrayerLog.Create(UserId, PrayerName.Fajr, Today,
            isOffered: false,
            waqtStatus: WaqtStatus.AwwalAlWaqt,
            missedReason: MissedReason.ExcusedSleep);

        act.Should().Throw<DomainException>()
            .WithMessage("*WaqtStatus must not be set*");
    }

    [Theory]
    [InlineData(PrayerName.Fajr)]
    [InlineData(PrayerName.Asr)]
    [InlineData(PrayerName.Maghrib)]
    [InlineData(PrayerName.Isha)]
    public void Create_JummahOnNonDhuhr_ThrowsDomainException(PrayerName prayer)
    {
        var act = () => PrayerLog.Create(UserId, prayer, Today,
            isOffered: true,
            waqtStatus: WaqtStatus.AwwalAlWaqt,
            isJummah: true);

        act.Should().Throw<DomainException>()
            .WithMessage("*IsJummah*Dhuhr*");
    }

    [Fact]
    public void Create_JummahOnDhuhr_Succeeds()
    {
        var act = () => PrayerLog.Create(UserId, PrayerName.Dhuhr, Today,
            isOffered: true,
            waqtStatus: WaqtStatus.AwwalAlWaqt,
            isJummah: true);

        act.Should().NotThrow();
    }

    [Fact]
    public void ClearDomainEvents_RemovesAllEvents()
    {
        var log = PrayerLog.Create(UserId, PrayerName.Maghrib, Today,
            isOffered: false, missedReason: MissedReason.ExcusedSleep);

        log.DomainEvents.Should().NotBeEmpty();
        log.ClearDomainEvents();
        log.DomainEvents.Should().BeEmpty();
    }
}
