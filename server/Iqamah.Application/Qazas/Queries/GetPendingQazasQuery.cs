using FluentValidation;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Interfaces.Repositories;
using MediatR;

namespace Iqamah.Application.Qazas.Queries;

public sealed record GetPendingQazasQuery(int UserId) : IRequest<IReadOnlyList<PendingQazaResponse>>;

public sealed class GetPendingQazasQueryValidator : AbstractValidator<GetPendingQazasQuery>
{
    public GetPendingQazasQueryValidator()
    {
        RuleFor(x => x.UserId)
            .GreaterThan(0).WithMessage("UserId must be greater than 0.");
    }
}

public sealed record PendingQazaResponse(
    Guid Id,
    Guid PrayerLogId,
    int UserId,
    PrayerName PrayerName,
    DateOnly OriginalPrayerDate,
    QazaState State,
    DateTime CreatedAt);

public sealed class GetPendingQazasQueryHandler : IRequestHandler<GetPendingQazasQuery, IReadOnlyList<PendingQazaResponse>>
{
    private readonly IQazaLogRepository _qazaLogRepository;

    public GetPendingQazasQueryHandler(IQazaLogRepository qazaLogRepository)
    {
        _qazaLogRepository = qazaLogRepository;
    }

    public async Task<IReadOnlyList<PendingQazaResponse>> Handle(GetPendingQazasQuery request, CancellationToken cancellationToken)
    {
        var qazas = await _qazaLogRepository.GetPendingByUserAsync(request.UserId, cancellationToken);

        return qazas.Select(x => new PendingQazaResponse(
            x.Id,
            x.PrayerLogId,
            x.UserId,
            x.PrayerName,
            x.OriginalPrayerDate,
            x.State,
            x.CreatedAt
        )).ToList();
    }
}
