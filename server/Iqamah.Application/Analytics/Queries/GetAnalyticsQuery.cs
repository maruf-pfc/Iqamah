using FluentValidation;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Interfaces.Repositories;
using MediatR;

namespace Iqamah.Application.Analytics.Queries;

public sealed record GetAnalyticsQuery(
    int UserId,
    DateOnly FromDate,
    DateOnly ToDate) : IRequest<AnalyticsResponse>;

public sealed class GetAnalyticsQueryValidator : AbstractValidator<GetAnalyticsQuery>
{
    public GetAnalyticsQueryValidator()
    {
        RuleFor(x => x.UserId)
            .GreaterThan(0).WithMessage("UserId must be greater than 0.");

        RuleFor(x => x.FromDate)
            .LessThanOrEqualTo(x => x.ToDate).WithMessage("FromDate must be less than or equal to ToDate.");
    }
}

public sealed record AnalyticsResponse(
    int TotalLogged,
    int TotalObligated, // Excludes ExcusedImpurity
    int TotalOffered,
    int TotalMissed,
    double OfferedPercentage, // TotalOffered / TotalObligated
    PunctualityStats Punctuality,
    MissedReasonsStats MissedReasons,
    Dictionary<string, PrayerSpecificStats> PrayerStats,
    QazaSummaryStats QazaSummary);

public sealed record PunctualityStats(
    int AwwalAlWaqtCount,
    int WastAlWaqtCount,
    int AkhirAlWaqtCount,
    double AwwalAlWaqtPercentage,
    double WastAlWaqtPercentage,
    double AkhirAlWaqtPercentage);

public sealed record MissedReasonsStats(
    int ExcusedImpurityCount,
    int ExcusedSleepCount,
    int ExcusedForgetfulnessCount,
    int UnexcusedSituationalCount,
    int UnexcusedLazinessCount,
    int UnexcusedDistractionCount,
    int TotalExcused,
    int TotalUnexcused);

public sealed record PrayerSpecificStats(
    int TotalObligated,
    int TotalOffered,
    double OfferedPercentage,
    int JamaahCount,
    double JamaahPercentage,
    int TravelingCount);

public sealed record QazaSummaryStats(
    int TotalPending,
    int TotalFulfilled,
    int TotalIncurred,
    double AverageResolutionTimeHours);

public sealed class GetAnalyticsQueryHandler : IRequestHandler<GetAnalyticsQuery, AnalyticsResponse>
{
    private readonly IPrayerLogRepository _prayerLogRepository;
    private readonly IQazaLogRepository _qazaLogRepository;

    public GetAnalyticsQueryHandler(
        IPrayerLogRepository prayerLogRepository,
        IQazaLogRepository qazaLogRepository)
    {
        _prayerLogRepository = prayerLogRepository;
        _qazaLogRepository = qazaLogRepository;
    }

    public async Task<AnalyticsResponse> Handle(GetAnalyticsQuery request, CancellationToken cancellationToken)
    {
        // 1. Fetch all prayer logs in range
        var logs = await _prayerLogRepository.GetByUserAndDateRangeAsync(
            request.UserId, request.FromDate, request.ToDate, cancellationToken);

        // 2. Fetch all Qaza logs for user (to compute accurate metrics)
        var allQazas = await _qazaLogRepository.GetByUserAndStateAsync(
            request.UserId, QazaState.Offered, cancellationToken);
        var pendingCount = await _qazaLogRepository.CountPendingAsync(request.UserId, cancellationToken);

        // Calculate totals
        var totalLogged = logs.Count;
        var totalObligated = logs.Count(x => x.MissedReason != MissedReason.ExcusedImpurity);
        var totalOffered = logs.Count(x => x.IsOffered);
        var totalMissed = totalObligated - totalOffered;

        var offeredPercentage = totalObligated > 0 
            ? Math.Round((double)totalOffered / totalObligated * 100, 2) 
            : 0;

        // Punctuality
        var awwalCount = logs.Count(x => x.IsOffered && x.WaqtStatus == WaqtStatus.AwwalAlWaqt);
        var wastCount = logs.Count(x => x.IsOffered && x.WaqtStatus == WaqtStatus.WastAlWaqt);
        var akhirCount = logs.Count(x => x.IsOffered && x.WaqtStatus == WaqtStatus.AkhirAlWaqt);

        var punctuality = new PunctualityStats(
            awwalCount,
            wastCount,
            akhirCount,
            totalOffered > 0 ? Math.Round((double)awwalCount / totalOffered * 100, 2) : 0,
            totalOffered > 0 ? Math.Round((double)wastCount / totalOffered * 100, 2) : 0,
            totalOffered > 0 ? Math.Round((double)akhirCount / totalOffered * 100, 2) : 0
        );

        // Missed reasons
        var impurityCount = logs.Count(x => !x.IsOffered && x.MissedReason == MissedReason.ExcusedImpurity);
        var sleepCount = logs.Count(x => !x.IsOffered && x.MissedReason == MissedReason.ExcusedSleep);
        var forgetCount = logs.Count(x => !x.IsOffered && x.MissedReason == MissedReason.ExcusedForgetfulness);
        var situationalCount = logs.Count(x => !x.IsOffered && x.MissedReason == MissedReason.UnexcusedSituational);
        var lazinessCount = logs.Count(x => !x.IsOffered && x.MissedReason == MissedReason.UnexcusedLaziness);
        var distractionCount = logs.Count(x => !x.IsOffered && x.MissedReason == MissedReason.UnexcusedDistraction);

        var totalExcused = sleepCount + forgetCount; // ExcusedImpurity has no obligation, so not counted as missed obligation
        var totalUnexcused = situationalCount + lazinessCount + distractionCount;

        var missedReasons = new MissedReasonsStats(
            impurityCount,
            sleepCount,
            forgetCount,
            situationalCount,
            lazinessCount,
            distractionCount,
            totalExcused,
            totalUnexcused
        );

        // Prayer specific statistics
        var prayerStats = new Dictionary<string, PrayerSpecificStats>();
        foreach (PrayerName name in Enum.GetValues<PrayerName>())
        {
            var prayerLogs = logs.Where(x => x.PrayerName == name).ToList();
            var pObligated = prayerLogs.Count(x => x.MissedReason != MissedReason.ExcusedImpurity);
            var pOffered = prayerLogs.Count(x => x.IsOffered);
            var pJamaah = prayerLogs.Count(x => x.IsOffered && x.IsJamaah);
            var pTraveling = prayerLogs.Count(x => x.IsTraveling);

            prayerStats[name.ToString().ToLower()] = new PrayerSpecificStats(
                pObligated,
                pOffered,
                pObligated > 0 ? Math.Round((double)pOffered / pObligated * 100, 2) : 0,
                pJamaah,
                pOffered > 0 ? Math.Round((double)pJamaah / pOffered * 100, 2) : 0,
                pTraveling
            );
        }

        // Qaza statistics
        var fulfilledCount = allQazas.Count;
        var totalIncurred = pendingCount + fulfilledCount;

        double avgResolutionTimeHours = 0;
        if (fulfilledCount > 0)
        {
            var validDurations = allQazas
                .Where(x => x.TimeToResolution.HasValue)
                .Select(x => x.TimeToResolution!.Value.TotalHours)
                .ToList();

            if (validDurations.Any())
            {
                avgResolutionTimeHours = Math.Round(validDurations.Average(), 2);
            }
        }

        var qazaSummary = new QazaSummaryStats(
            pendingCount,
            fulfilledCount,
            totalIncurred,
            avgResolutionTimeHours
        );

        return new AnalyticsResponse(
            totalLogged,
            totalObligated,
            totalOffered,
            totalMissed,
            offeredPercentage,
            punctuality,
            missedReasons,
            prayerStats,
            qazaSummary
        );
    }
}
