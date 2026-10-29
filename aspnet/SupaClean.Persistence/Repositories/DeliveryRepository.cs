using Microsoft.EntityFrameworkCore;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;

namespace SupaClean.Persistence.Repositories
{
    public class DeliveryRepository : Repository<Delivery>, IDeliveryRepository
    {
        public DeliveryRepository(AppDbContext db) : base(db) { }

        // The driver, their employee record and their user, so a screen can show a name.
        private IQueryable<Delivery> WithDriver
            => _set.Include(d => d.Driver).ThenInclude(dr => dr.Employee).ThenInclude(e => e.User);

        public async Task<IReadOnlyList<Delivery>> GetForOrdersAsync(IEnumerable<Guid> orderIds)
        {
            var ids = orderIds.Distinct().ToList();
            if (ids.Count == 0) return new List<Delivery>();

            // Not tracked: this is only for showing, and a page that stays open must
            // not keep an old copy of who had a job.
            return await WithDriver.AsNoTracking().Where(d => ids.Contains(d.OrderId)).ToListAsync();
        }

        public async Task<Delivery?> GetOpenAsync(Guid orderId, DeliveryType type)
            => await WithDriver.FirstOrDefaultAsync(d => d.OrderId == orderId
                                                         && d.DeliveryType == type
                                                         && d.CompletedAt == null);

        public async Task<IReadOnlyList<Delivery>> GetOpenForUserAsync(Guid userId)
            => await _set.AsNoTracking()
                         .Where(d => d.CompletedAt == null && d.Driver.Employee.UserId == userId)
                         .ToListAsync();
    }
}
