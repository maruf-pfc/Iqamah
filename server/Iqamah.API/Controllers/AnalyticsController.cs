using System;
using System.Threading;
using System.Threading.Tasks;
using Iqamah.Application.Analytics.Queries;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iqamah.API.Controllers;

[Authorize]
public sealed class AnalyticsController : ApiControllerBase
{
    [HttpGet]
    public async Task<ActionResult<AnalyticsResponse>> GetAnalytics(
        [FromQuery] DateOnly from,
        [FromQuery] DateOnly to,
        CancellationToken ct)
    {
        var query = new GetAnalyticsQuery(CurrentUserId, from, to);
        var result = await Mediator.Send(query, ct);
        return Ok(result);
    }
}
