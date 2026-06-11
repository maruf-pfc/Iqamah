using Iqamah.Application.Prayers.Commands;
using Iqamah.Application.Prayers.Queries;
using Iqamah.Domain.Enums;
using Microsoft.AspNetCore.Mvc;

namespace Iqamah.API.Controllers;

public sealed class PrayersController : ApiControllerBase
{
    [HttpPost]
    public async Task<ActionResult<Guid>> LogPrayer(
        [FromBody] LogPrayerRequest request,
        CancellationToken ct)
    {
        var command = new LogPrayerCommand(
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

        var result = await Mediator.Send(command, ct);
        return Ok(result);
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<PrayerLogResponse>>> GetPrayerLogs(
        [FromQuery] int userId,
        [FromQuery] DateOnly from,
        [FromQuery] DateOnly to,
        CancellationToken ct)
    {
        var query = new GetPrayerLogsQuery(userId, from, to);
        var result = await Mediator.Send(query, ct);
        return Ok(result);
    }
}

public sealed record LogPrayerRequest(
    int UserId,
    PrayerName PrayerName,
    DateOnly PrayerDate,
    bool IsOffered,
    WaqtStatus? WaqtStatus,
    MissedReason? MissedReason,
    bool IsJamaah,
    bool IsTraveling,
    bool IsJummah);
