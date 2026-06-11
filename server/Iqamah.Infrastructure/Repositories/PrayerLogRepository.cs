using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Interfaces.Repositories;
using Iqamah.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Iqamah.Infrastructure.Repositories;

public sealed class PrayerLogRepository : IPrayerLogRepository
{
    private readonly AppDbContext _context;

    public PrayerLogRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PrayerLog?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        return await _context.PrayerLogs
            .Include(x => x.QazaLog)
            .FirstOrDefaultAsync(x => x.Id == id, ct);
    }

    public async Task<IReadOnlyList<PrayerLog>> GetByUserAndDateRangeAsync(
        int userId, DateOnly from, DateOnly to, CancellationToken ct = default)
    {
        var list = await _context.PrayerLogs
            .AsNoTracking()
            .Include(x => x.QazaLog)
            .Where(x => x.UserId == userId && x.PrayerDate >= from && x.PrayerDate <= to)
            .OrderBy(x => x.PrayerDate)
            .ThenBy(x => x.PrayerName)
            .ToListAsync(ct);

        return list;
    }

    public async Task<PrayerLog?> GetByUserDateAndPrayerAsync(
        int userId, DateOnly date, PrayerName prayer, CancellationToken ct = default)
    {
        return await _context.PrayerLogs
            .Include(x => x.QazaLog)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.PrayerDate == date && x.PrayerName == prayer, ct);
    }

    public async Task AddAsync(PrayerLog log, CancellationToken ct = default)
    {
        await _context.PrayerLogs.AddAsync(log, ct);
    }

    public async Task<int> SaveChangesAsync(CancellationToken ct = default)
    {
        return await _context.SaveChangesAsync(ct);
    }
}
