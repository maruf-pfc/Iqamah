using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Iqamah.Application.Common.Interfaces;
using Iqamah.Application.Common.Models;
using Microsoft.Extensions.Caching.Memory;

namespace Iqamah.Infrastructure.Services;

public class PrayerTimeService : IPrayerTimeService
{
    private readonly HttpClient _http;
    private readonly IMemoryCache _cache;
    private const string BASE_URL = "https://api.aladhan.com/v1";

    public PrayerTimeService(HttpClient http, IMemoryCache cache)
    {
        _http = http;
        _cache = cache;
    }

    public async Task<PrayerSchedule> GetScheduleAsync(double lat, double lng, DateOnly date)
    {
        var cacheKey = $"prayer_{lat:F4}_{lng:F4}_{date:yyyyMMdd}";
        if (_cache.TryGetValue(cacheKey, out PrayerSchedule? schedule) && schedule != null)
        {
            return schedule;
        }

        schedule = await FetchFromApiAsync(lat, lng, date);

        var expiry = date.ToDateTime(TimeOnly.MinValue).AddDays(1); // Expires at midnight of next day
        _cache.Set(cacheKey, schedule, new MemoryCacheEntryOptions
        {
            AbsoluteExpiration = new DateTimeOffset(expiry, TimeSpan.FromHours(6)) // Offset for Bangladesh/local tz
        });

        return schedule;
    }

    private async Task<PrayerSchedule> FetchFromApiAsync(double lat, double lng, DateOnly date)
    {
        var dateTime = date.ToDateTime(TimeOnly.MinValue);
        // Using a fixed +06:00 offset (Bangladesh Standard Time) to match local calculation
        var localDateTimeOffset = new DateTimeOffset(dateTime, TimeSpan.FromHours(6));
        var ts = localDateTimeOffset.ToUnixTimeSeconds();

        var url = $"{BASE_URL}/timings/{ts}?latitude={lat}&longitude={lng}&method=1&school=1";
        
        var response = await _http.GetAsync(url);
        response.EnsureSuccessStatusCode();

        var jsonString = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(jsonString);
        var timings = document.RootElement
            .GetProperty("data")
            .GetProperty("timings");

        var fajr = ParseTime(timings, "Fajr", date);
        var sunrise = ParseTime(timings, "Sunrise", date);
        var dhuhr = ParseTime(timings, "Dhuhr", date);
        var asr = ParseTime(timings, "Asr", date);
        var sunset = ParseTime(timings, "Sunset", date);
        var maghrib = ParseTime(timings, "Maghrib", date);
        var isha = ParseTime(timings, "Isha", date);
        var midnight = ParseTime(timings, "Midnight", date);

        // Midnight check: if midnight is before isha, it represents the next calendar day
        if (midnight < isha)
        {
            midnight = midnight.AddDays(1);
        }

        var dateElement = document.RootElement.GetProperty("data").GetProperty("date");
        var hijri = dateElement.GetProperty("hijri");
        var hijriDay = hijri.GetProperty("day").ToString();
        var hijriMonth = hijri.GetProperty("month").GetProperty("en").ToString();
        var hijriYear = hijri.GetProperty("year").ToString();
        var hijriDate = $"{hijriDay} {hijriMonth} {hijriYear} AH";

        return new PrayerSchedule
        {
            Fajr = new PrayerEntry(fajr, sunrise, "Fajr"),
            Dhuhr = new PrayerEntry(dhuhr, asr, "Dhuhr"),
            Asr = new PrayerEntry(asr, sunset, "Asr"),
            Maghrib = new PrayerEntry(maghrib, isha, "Maghrib"),
            Isha = new PrayerEntry(isha, midnight, "Isha"),
            Sunrise = sunrise,
            HijriDate = hijriDate,
            ForbiddenZones = new List<ForbiddenZone>
            {
                new("Sunrise (Shuruq)", sunrise, sunrise.AddMinutes(15)),
                new("Solar Noon (Zawaal)", dhuhr.AddMinutes(-5), dhuhr),
                new("Sunset (Ghurub)", sunset.AddMinutes(-15), sunset)
            }
        };
    }

    private static DateTime ParseTime(JsonElement timings, string key, DateOnly date)
    {
        var timeStr = timings.GetProperty(key).GetString()!;
        var parts = timeStr.Split(':', StringSplitOptions.TrimEntries);
        var hours = int.Parse(parts[0]);
        var minutes = int.Parse(parts[1]);

        return new DateTime(date.Year, date.Month, date.Day, hours, minutes, 0);
    }
}
