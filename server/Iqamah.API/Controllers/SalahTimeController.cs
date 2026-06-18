using System;
using System.Threading.Tasks;
using Iqamah.Application.Common.Interfaces;
using Iqamah.Application.Common.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Iqamah.API.Controllers;

[AllowAnonymous]
public sealed class SalahTimeController : ApiControllerBase
{
    private readonly IPrayerTimeService _prayerTimeService;

    public SalahTimeController(IPrayerTimeService prayerTimeService)
    {
        _prayerTimeService = prayerTimeService;
    }

    [HttpGet]
    public async Task<ActionResult<PrayerSchedule>> GetSalahTime(
        [FromQuery] double latitude,
        [FromQuery] double longitude,
        [FromQuery] DateOnly? date)
    {
        try
        {
            var targetDate = date ?? DateOnly.FromDateTime(DateTime.Today);
            var schedule = await _prayerTimeService.GetScheduleAsync(latitude, longitude, targetDate);
            return Ok(schedule);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
