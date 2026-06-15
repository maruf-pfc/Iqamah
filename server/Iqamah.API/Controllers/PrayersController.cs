using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Iqamah.Application.Prayers.Commands;
using Iqamah.Application.Prayers.Queries;
using Iqamah.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iqamah.API.Controllers;

[Authorize]
public sealed class PrayersController : ApiControllerBase
{
    [HttpPost]
    public async Task<ActionResult<Guid>> LogPrayer(
        [FromBody] LogPrayerRequest request,
        CancellationToken ct)
    {
        var command = new LogPrayerCommand(
            CurrentUserId, // Read from authenticated JWT claims
            request.PrayerName,
            request.PrayerDate,
            request.IsOffered,
            request.WaqtStatus,
            request.MissedReason,
            request.IsJamaah,
            request.IsTraveling,
            request.IsJummah,
            request.IsHome,
            request.QuranNotes,
            request.HasTasbih
        );

        var result = await Mediator.Send(command, ct);
        return Ok(result);
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<PrayerLogResponse>>> GetPrayerLogs(
        [FromQuery] DateOnly from,
        [FromQuery] DateOnly to,
        CancellationToken ct)
    {
        var query = new GetPrayerLogsQuery(CurrentUserId, from, to); // Read from authenticated JWT claims
        var result = await Mediator.Send(query, ct);
        return Ok(result);
    }
}

public sealed record LogPrayerRequest(
    PrayerName PrayerName,
    DateOnly PrayerDate,
    bool IsOffered,
    WaqtStatus? WaqtStatus,
    MissedReason? MissedReason,
    bool IsJamaah,
    bool IsTraveling,
    bool IsJummah,
    bool IsHome = false,
    string? QuranNotes = null,
    bool HasTasbih = false);
