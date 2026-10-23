using SupaClean.Application.Contracts;
using Microsoft.EntityFrameworkCore;
using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Repositories
{
    public class NotificationRepository : Repository<Notification>, INotificationRepository
    {
        public NotificationRepository(AppDbContext db) : base(db) { }

        public async Task<IEnumerable<Notification>> GetByCustomerIdAsync(Guid customerId)
            => await _set.Where(n => n.CustomerId == customerId)
                         .OrderByDescending(n => n.SentAt)
                         .Take(100)
                         .ToListAsync();
    }
}
