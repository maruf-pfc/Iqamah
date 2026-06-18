using System;
using System.Threading.Tasks;
using Iqamah.Application.Common.Models;

namespace Iqamah.Application.Common.Interfaces;

public interface IPrayerTimeService
{
    Task<PrayerSchedule> GetScheduleAsync(double lat, double lng, DateOnly date);
}
