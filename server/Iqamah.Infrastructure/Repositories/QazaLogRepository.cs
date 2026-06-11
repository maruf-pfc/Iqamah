using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Interfaces.Repositories;
using Iqamah.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Iqamah.Infrastructure.Repositories;

public sealed class QazaLogRepository : IQazaLogRepository
{
    private readonly AppDbContext _context;

    public QazaLogRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<QazaLog?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        return await _context.QazaLogs
            .Include(x => x.PrayerLog)
            .FirstOrDefaultAsync(x => x.Id == id, ct);
    }

    public async Task<IReadOnlyList<QazaLog>> GetPendingByUserAsync(int userId, CancellationToken ct = default)
    {
        var list = await _context.QazaLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.State == QazaState.Pending)
            .OrderBy(x => x.OriginalPrayerDate)
            .ThenBy(x => x.PrayerName)
            .ToListAsync(ct);

        return list;
    }

    public async Task<IReadOnlyList<QazaLog>> GetByUserAndStateAsync(
        int userId, QazaState state, CancellationToken ct = default)
    {
        var list = await _context.QazaLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.State == state)
            .OrderBy(x => x.OriginalPrayerDate)
            .ThenBy(x => x.PrayerName)
            .ToListAsync(ct);

        return list;
    }

    public async Task<int> CountPendingAsync(int userId, CancellationToken ct = default)
    {
        return await _context.QazaLogs
            .CountAsync(x => x.UserId == userId && x.State == QazaState.Pending, ct);
    }

    public async Task AddAsync(QazaLog log, CancellationToken ct = default)
    {
        await _context.QazaLogs.AddAsync(log, ct);
    }

    public void Delete(QazaLog log)
    {
        _context.QazaLogs.Remove(log);
    }

    public async Task<int> SaveChangesAsync(CancellationToken ct = default)
    {
        return await _context.SaveChangesAsync(ct);
    }
}
