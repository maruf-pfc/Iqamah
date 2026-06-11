using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Iqamah.Application.Qazas.Commands;
using Iqamah.Application.Qazas.Queries;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iqamah.API.Controllers;

[Authorize]
public sealed class QazasController : ApiControllerBase
{
    [HttpGet("pending")]
    public async Task<ActionResult<IReadOnlyList<PendingQazaResponse>>> GetPendingQazas(CancellationToken ct)
    {
        var query = new GetPendingQazasQuery(CurrentUserId);
        var result = await Mediator.Send(query, ct);
        return Ok(result);
    }

    [HttpPost("{id:guid}/fulfill")]
    public async Task<ActionResult> FulfillQaza(
        [FromRoute] Guid id,
        CancellationToken ct)
    {
        var command = new FulfillQazaCommand(id, CurrentUserId);
        await Mediator.Send(command, ct);
        return NoContent();
    }
}
