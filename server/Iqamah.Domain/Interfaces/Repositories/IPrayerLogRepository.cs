using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;

namespace Iqamah.Domain.Interfaces.Repositories;

/// <summary>Repository abstraction for <see cref="PrayerLog"/> persistence.</summary>
public interface IPrayerLogRepository
{
    Task<PrayerLog?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<PrayerLog>> GetByUserAndDateRangeAsync(
        int userId, DateOnly from, DateOnly to, CancellationToken ct = default);
    Task<PrayerLog?> GetByUserDateAndPrayerAsync(
        int userId, DateOnly date, PrayerName prayer, CancellationToken ct = default);
    Task AddAsync(PrayerLog log, CancellationToken ct = default);
    Task<int> SaveChangesAsync(CancellationToken ct = default);
}
