using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;

namespace Iqamah.Domain.Interfaces.Repositories;

/// <summary>Repository abstraction for <see cref="QazaLog"/> persistence.</summary>
public interface IQazaLogRepository
{
    Task<QazaLog?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<QazaLog>> GetPendingByUserAsync(int userId, CancellationToken ct = default);
    Task<IReadOnlyList<QazaLog>> GetByUserAndStateAsync(
        int userId, QazaState state, CancellationToken ct = default);
    Task<int> CountPendingAsync(int userId, CancellationToken ct = default);
    Task AddAsync(QazaLog log, CancellationToken ct = default);
    void Delete(QazaLog log);
    Task<int> SaveChangesAsync(CancellationToken ct = default);
}
