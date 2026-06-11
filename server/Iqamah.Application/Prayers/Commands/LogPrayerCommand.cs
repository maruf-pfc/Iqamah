using FluentValidation;
using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Exceptions;
using Iqamah.Domain.Interfaces.Repositories;
using MediatR;

namespace Iqamah.Application.Prayers.Commands;

public sealed record LogPrayerCommand(
    int UserId,
    PrayerName PrayerName,
    DateOnly PrayerDate,
    bool IsOffered,
    WaqtStatus? WaqtStatus = null,
    MissedReason? MissedReason = null,
    bool IsJamaah = false,
    bool IsTraveling = false,
    bool IsJummah = false) : IRequest<Guid>;

public sealed class LogPrayerCommandValidator : AbstractValidator<LogPrayerCommand>
{
    public LogPrayerCommandValidator()
    {
        RuleFor(x => x.UserId)
            .GreaterThan(0).WithMessage("UserId must be greater than 0.");

        RuleFor(x => x.PrayerDate)
            .LessThanOrEqualTo(_ => DateOnly.FromDateTime(DateTime.UtcNow))
            .WithMessage("Prayer date cannot be in the future.");

        RuleFor(x => x.WaqtStatus)
            .NotNull().When(x => x.IsOffered).WithMessage("WaqtStatus is required when a prayer is offered.")
            .Null().When(x => !x.IsOffered).WithMessage("WaqtStatus must not be set when a prayer is missed.");

        RuleFor(x => x.MissedReason)
            .NotNull().When(x => !x.IsOffered).WithMessage("MissedReason is required when a prayer is missed.")
            .Null().When(x => x.IsOffered).WithMessage("MissedReason must not be set when a prayer is offered.");

        RuleFor(x => x.IsJummah)
            .Must((cmd, isJummah) => !isJummah || cmd.PrayerName == PrayerName.Dhuhr)
            .WithMessage("IsJummah can only be set for the Dhuhr prayer.");
    }
}

public sealed class LogPrayerCommandHandler : IRequestHandler<LogPrayerCommand, Guid>
{
    private readonly IPrayerLogRepository _prayerLogRepository;
    private readonly IQazaLogRepository _qazaLogRepository;

    public LogPrayerCommandHandler(
        IPrayerLogRepository prayerLogRepository,
        IQazaLogRepository qazaLogRepository)
    {
        _prayerLogRepository = prayerLogRepository;
        _qazaLogRepository = qazaLogRepository;
    }

    public async Task<Guid> Handle(LogPrayerCommand request, CancellationToken cancellationToken)
    {
        var existingLog = await _prayerLogRepository.GetByUserDateAndPrayerAsync(
            request.UserId, request.PrayerDate, request.PrayerName, cancellationToken);

        if (existingLog == null)
        {
            var newLog = PrayerLog.Create(
                request.UserId,
                request.PrayerName,
                request.PrayerDate,
                request.IsOffered,
                request.WaqtStatus,
                request.MissedReason,
                request.IsJamaah,
                request.IsTraveling,
                request.IsJummah
            );

            await _prayerLogRepository.AddAsync(newLog, cancellationToken);
            await _prayerLogRepository.SaveChangesAsync(cancellationToken);
            return newLog.Id;
        }

        // Handle updates/corrections
        var wasRequiringQaza = existingLog.RequiresQaza();
        var oldQaza = existingLog.QazaLog;

        existingLog.Update(
            request.IsOffered,
            request.WaqtStatus,
            request.MissedReason,
            request.IsJamaah,
            request.IsTraveling,
            request.IsJummah
        );

        var isNowRequiringQaza = existingLog.RequiresQaza();

        // State Transition logic for corrections:
        if (!isNowRequiringQaza && wasRequiringQaza && oldQaza != null)
        {
            // The prayer is now marked as offered (on-time), so the Qaza debt is deleted.
            // If the user already fulfilled the Qaza, we prevent changing the original log to offered
            // since that would be historically contradictory.
            if (oldQaza.IsFulfilled)
            {
                throw new DomainException("Cannot modify the original prayer to 'On-Time' because the associated Qaza has already been fulfilled.");
            }

            _qazaLogRepository.Delete(oldQaza);
        }

        await _prayerLogRepository.SaveChangesAsync(cancellationToken);
        return existingLog.Id;
    }
}
