using Iqamah.Application.Analytics.Queries;
using Microsoft.AspNetCore.Mvc;

namespace Iqamah.API.Controllers;

public sealed class AnalyticsController : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<AnalyticsResponse>> GetAnalytics(
        [FromQuery] int userId,
        [FromQuery] DateOnly from,
        [FromQuery] DateOnly to,
        CancellationToken ct)
    {
        var query = new GetAnalyticsQuery(userId, from, to);
        var result = await Mediator.Send(query, ct);
        return Ok(result);
    }
}
