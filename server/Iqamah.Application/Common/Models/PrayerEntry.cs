using System;

namespace Iqamah.Application.Common.Models;

public record PrayerEntry(
    DateTime Start,
    DateTime End,
    string Name)
{
    public TimeSpan Remaining => Start - DateTime.Now;
    public bool IsActive => DateTime.Now >= Start && DateTime.Now < End;
}
