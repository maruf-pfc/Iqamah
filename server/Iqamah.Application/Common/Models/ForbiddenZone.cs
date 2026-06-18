using System;

namespace Iqamah.Application.Common.Models;

public record ForbiddenZone(
    string Name,
    DateTime Start,
    DateTime End)
{
    public bool IsActive => DateTime.Now >= Start && DateTime.Now < End;
}
