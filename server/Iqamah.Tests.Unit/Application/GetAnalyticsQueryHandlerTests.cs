using FluentAssertions;
using Iqamah.Application.Analytics.Queries;
using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Interfaces.Repositories;
using NSubstitute;

namespace Iqamah.Tests.Unit.Application;

public sealed class GetAnalyticsQueryHandlerTests
{
    private readonly IPrayerLogRepository _prayerLogRepository;
    private readonly IQazaLogRepository _qazaLogRepository;
    private readonly GetAnalyticsQueryHandler _handler;

    private const int UserId = 15;
    private static readonly DateOnly From = new(2025, 1, 1);
    private static readonly DateOnly To = new(2025, 1, 10);

    public GetAnalyticsQueryHandlerTests()
    {
        _prayerLogRepository = Substitute.For<IPrayerLogRepository>();
        _qazaLogRepository = Substitute.For<IQazaLogRepository>();
        _handler = new GetAnalyticsQueryHandler(_prayerLogRepository, _qazaLogRepository);
    }

    [Fact]
    public async Task Handle_ValidRequest_CalculatesMetricsCorrectly()
    {
        // Arrange
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var prayerLogs = new List<PrayerLog>
        {
            // Fajr on-time
            PrayerLog.Create(UserId, PrayerName.Fajr, today, isOffered: true, waqtStatus: WaqtStatus.AwwalAlWaqt, isJamaah: true),
            // Dhuhr missed - Laziness
            PrayerLog.Create(UserId, PrayerName.Dhuhr, today, isOffered: false, missedReason: MissedReason.UnexcusedLaziness),
            // Asr missed - Impurity (Excluded from obligation)
            PrayerLog.Create(UserId, PrayerName.Asr, today, isOffered: false, missedReason: MissedReason.ExcusedImpurity),
            // Maghrib on-time
            PrayerLog.Create(UserId, PrayerName.Maghrib, today, isOffered: true, waqtStatus: WaqtStatus.WastAlWaqt, isTraveling: true),
            // Isha on-time
            PrayerLog.Create(UserId, PrayerName.Isha, today, isOffered: true, waqtStatus: WaqtStatus.AkhirAlWaqt)
        };

        _prayerLogRepository.GetByUserAndDateRangeAsync(UserId, From, To, Arg.Any<CancellationToken>())
            .Returns(prayerLogs);

        // Fulfill 2 Qaza logs (one took 2 hours, another took 4 hours)
        var q1 = QazaLog.CreatePending(Guid.NewGuid(), UserId, PrayerName.Dhuhr, today);
        typeof(QazaLog).GetProperty(nameof(QazaLog.CreatedAt))!.SetValue(q1, DateTime.UtcNow.AddHours(-2));
        q1.Fulfill();

        var q2 = QazaLog.CreatePending(Guid.NewGuid(), UserId, PrayerName.Asr, today);
        typeof(QazaLog).GetProperty(nameof(QazaLog.CreatedAt))!.SetValue(q2, DateTime.UtcNow.AddHours(-4));
        q2.Fulfill();

        var offeredQazas = new List<QazaLog> { q1, q2 };

        _qazaLogRepository.GetByUserAndStateAsync(UserId, QazaState.Offered, Arg.Any<CancellationToken>())
            .Returns(offeredQazas);

        _qazaLogRepository.CountPendingAsync(UserId, Arg.Any<CancellationToken>())
            .Returns(3); // 3 pending

        var query = new GetAnalyticsQuery(UserId, From, To);

        // Act
        var result = await _handler.Handle(query, CancellationToken.None);

        // Assert
        result.TotalLogged.Should().Be(5);
        result.TotalObligated.Should().Be(4); // Excludes impurity
        result.TotalOffered.Should().Be(3);
        result.TotalMissed.Should().Be(1);
        result.OfferedPercentage.Should().Be(75.0); // 3/4 * 100

        result.Punctuality.AwwalAlWaqtCount.Should().Be(1);
        result.Punctuality.WastAlWaqtCount.Should().Be(1);
        result.Punctuality.AkhirAlWaqtCount.Should().Be(1);
        result.Punctuality.AwwalAlWaqtPercentage.Should().Be(33.33); // 1/3 * 100

        result.MissedReasons.ExcusedImpurityCount.Should().Be(1);
        result.MissedReasons.UnexcusedLazinessCount.Should().Be(1);
        result.MissedReasons.TotalExcused.Should().Be(0); // Impurity doesn't count towards missed obligation excuse metrics
        result.MissedReasons.TotalUnexcused.Should().Be(1);

        result.PrayerStats["fajr"].TotalOffered.Should().Be(1);
        result.PrayerStats["fajr"].JamaahPercentage.Should().Be(100.0);

        result.QazaSummary.TotalFulfilled.Should().Be(2);
        result.QazaSummary.TotalPending.Should().Be(3);
        result.QazaSummary.TotalIncurred.Should().Be(5);
        result.QazaSummary.AverageResolutionTimeHours.Should().BeApproximately(3.0, 0.1); // Average of 2 and 4 hours
    }
}
