using Microsoft.EntityFrameworkCore;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;

namespace SupaClean.Persistence.Repositories
{
    public class PointsRepository : Repository<PointsTransaction>, IPointsRepository
    {
        public PointsRepository(AppDbContext db) : base(db) { }

        public async Task<int> GetBalanceAsync(Guid customerId)
            => await _set.Where(t => t.CustomerId == customerId).SumAsync(t => (int?)t.Points) ?? 0;

        public async Task<IReadOnlyList<PointsTransaction>> GetHistoryAsync(Guid customerId)
            => await _set.Where(t => t.CustomerId == customerId)
                         .OrderByDescending(t => t.CreatedAt)
                         .ToListAsync();

        public Task<bool> ExistsAsync(Guid orderId, PointsKind kind)
            => _set.AnyAsync(t => t.OrderId == orderId && t.Kind == kind);

        public async Task<int> SumForOrderAsync(Guid orderId, PointsKind kind)
            => await _set.Where(t => t.OrderId == orderId && t.Kind == kind).SumAsync(t => (int?)t.Points) ?? 0;
    }
}
