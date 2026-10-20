using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Contracts.Repositories
{
    public  interface IOrderRepository : IRepository<Order>
    {
        Task<IEnumerable<Order>> GetByCustomerIdAsync(Guid customerId);
        Task<Order?> GetWithItemsByIdAsync(Guid orderId);
        Task<IEnumerable<Order>> GetPendingOrdersAsync();
    }
}
