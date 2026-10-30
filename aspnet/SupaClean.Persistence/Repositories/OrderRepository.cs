using Microsoft.EntityFrameworkCore;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Repositories
{
    public class OrderRepository : Repository<Order>, IOrderRepository
    {
        public OrderRepository(AppDbContext db) : base(db) { }

        private IQueryable<Order> WithItems => _set.Include(o => o.OrderItems).Include(o => o.StatusHistory);

        public override async Task<Order?> GetByIdAsync(Guid id)
            => await WithItems.FirstOrDefaultAsync(o => o.OrderId == id);

        public override async Task<IEnumerable<Order>> GetAllAsync()
            => await WithItems.ToListAsync();

        public async Task<Order?> GetByOrderSequenceAsync(int sequence)
    => await WithItems.FirstOrDefaultAsync(o => o.OrderSequence == sequence);

        public async Task<Order?> GetWithItemsByIdAsync(Guid orderId)
            => await GetByIdAsync(orderId);

        public async Task<IEnumerable<Order>> GetDeliveryStopsAsync()
    => await _set.Include(o => o.Customer).ThenInclude(c => c.User)
                 .Where(o => o.FulfillmentMethod == Fulfillment_Method.Delivery
                          && (o.OrderStatus == OrderStatus.ReadyForCollection
                              || o.OrderStatus == OrderStatus.OutForDelivery))
                 .OrderBy(o => o.OrderDate)
                 .ToListAsync();

        public async Task<IEnumerable<Order>> GetByCustomerIdAsync(Guid customerId)
            => await WithItems.Where(o => o.CustomerId == customerId)
                              .OrderByDescending(o => o.OrderDate)
                              .ToListAsync();

        public async Task<IEnumerable<Order>> GetPendingOrdersAsync()
            => await WithItems.Where(o => o.OrderStatus == OrderStatus.PendingInTake)
                              .OrderBy(o => o.OrderDate)
                              .ToListAsync();
    }
}
