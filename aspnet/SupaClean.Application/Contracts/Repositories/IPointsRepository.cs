using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;

namespace SupaClean.Application.Contracts.Repositories
{
    public interface IPointsRepository : IRepository<PointsTransaction>
    {
        Task<int> GetBalanceAsync(Guid customerId);
        Task<IReadOnlyList<PointsTransaction>> GetHistoryAsync(Guid customerId);
        Task<bool> ExistsAsync(Guid orderId, PointsKind kind);
        Task<int> SumForOrderAsync(Guid orderId, PointsKind kind);
    }
}
