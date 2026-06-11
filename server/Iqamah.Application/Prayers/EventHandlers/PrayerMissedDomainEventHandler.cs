using Iqamah.Domain.Entities;
using Iqamah.Domain.Events;
using Iqamah.Domain.Interfaces.Repositories;
using MediatR;

namespace Iqamah.Application.Prayers.EventHandlers;

public sealed class PrayerMissedDomainEventHandler : INotificationHandler<PrayerMissedDomainEvent>
{
    private readonly IQazaLogRepository _qazaLogRepository;

    public PrayerMissedDomainEventHandler(IQazaLogRepository qazaLogRepository)
    {
        _qazaLogRepository = qazaLogRepository;
    }

    public async Task Handle(PrayerMissedDomainEvent notification, CancellationToken cancellationToken)
    {
        var qazaLog = QazaLog.CreatePending(
            notification.PrayerLogId,
            notification.UserId,
            notification.PrayerName,
            notification.PrayerDate
        );

        await _qazaLogRepository.AddAsync(qazaLog, cancellationToken);
    }
}
