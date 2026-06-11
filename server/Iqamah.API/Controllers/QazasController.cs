using Iqamah.Application.Qazas.Commands;
using Iqamah.Application.Qazas.Queries;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace Iqamah.API.Controllers;

public sealed class QazasController : ApiControllerBase
{
    [HttpGet("pending")]
    public async Task<ActionResult<IReadOnlyList<PendingQazaResponse>>> GetPendingQazas(
        [FromQuery] int userId,
        CancellationToken ct)
    {
        var query = new GetPendingQazasQuery(userId);
        var result = await Mediator.Send(query, ct);
        return Ok(result);
    }

    [HttpPost("{id:guid}/fulfill")]
    public async Task<ActionResult> FulfillQaza(
        [FromRoute] Guid id,
        [FromBody] FulfillQazaRequest request,
        CancellationToken ct)
    {
        var command = new FulfillQazaCommand(id, request.UserId);
        await Mediator.Send(command, ct);
        return NoContent();
    }
}

public sealed record FulfillQazaRequest(int UserId);
