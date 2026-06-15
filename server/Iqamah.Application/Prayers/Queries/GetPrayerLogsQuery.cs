using FluentValidation;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Interfaces.Repositories;
using MediatR;

namespace Iqamah.Application.Prayers.Queries;

public sealed record GetPrayerLogsQuery(
    int UserId,
    DateOnly FromDate,
    DateOnly ToDate) : IRequest<IReadOnlyList<PrayerLogResponse>>;

public sealed class GetPrayerLogsQueryValidator : AbstractValidator<GetPrayerLogsQuery>
{
    public GetPrayerLogsQueryValidator()
    {
        RuleFor(x => x.UserId)
            .GreaterThan(0).WithMessage("UserId must be greater than 0.");

        RuleFor(x => x.FromDate)
            .LessThanOrEqualTo(x => x.ToDate).WithMessage("FromDate must be less than or equal to ToDate.");
    }
}

public sealed record PrayerLogResponse(
    Guid Id,
    int UserId,
    PrayerName PrayerName,
    DateOnly PrayerDate,
    bool IsOffered,
    WaqtStatus? WaqtStatus,
    MissedReason? MissedReason,
    bool IsJamaah,
    bool IsTraveling,
    bool IsJummah,
    bool IsHome,
    string? QuranNotes,
    bool HasTasbih,
    DateTime LoggedAt,
    QazaLogResponse? QazaLog);

public sealed record QazaLogResponse(
    Guid Id,
    Guid PrayerLogId,
    int UserId,
    PrayerName PrayerName,
    DateOnly OriginalPrayerDate,
    QazaState State,
    DateTime CreatedAt,
    DateTime? FulfilledAt,
    double? TimeToResolutionSeconds);

public sealed class GetPrayerLogsQueryHandler : IRequestHandler<GetPrayerLogsQuery, IReadOnlyList<PrayerLogResponse>>
{
    private readonly IPrayerLogRepository _prayerLogRepository;

    public GetPrayerLogsQueryHandler(IPrayerLogRepository prayerLogRepository)
    {
        _prayerLogRepository = prayerLogRepository;
    }

    public async Task<IReadOnlyList<PrayerLogResponse>> Handle(GetPrayerLogsQuery request, CancellationToken cancellationToken)
    {
        var logs = await _prayerLogRepository.GetByUserAndDateRangeAsync(
            request.UserId, request.FromDate, request.ToDate, cancellationToken);

        return logs.Select(x => new PrayerLogResponse(
            x.Id,
            x.UserId,
            x.PrayerName,
            x.PrayerDate,
            x.IsOffered,
            x.WaqtStatus,
            x.MissedReason,
            x.IsJamaah,
            x.IsTraveling,
            x.IsJummah,
            x.IsHome,
            x.QuranNotes,
            x.HasTasbih,
            x.LoggedAt,
            x.QazaLog == null ? null : new QazaLogResponse(
                x.QazaLog.Id,
                x.QazaLog.PrayerLogId,
                x.QazaLog.UserId,
                x.QazaLog.PrayerName,
                x.QazaLog.OriginalPrayerDate,
                x.QazaLog.State,
                x.QazaLog.CreatedAt,
                x.QazaLog.FulfilledAt,
                x.QazaLog.TimeToResolution?.TotalSeconds
            )
        )).ToList();
    }
}
