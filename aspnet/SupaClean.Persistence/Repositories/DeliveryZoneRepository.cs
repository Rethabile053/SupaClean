using Microsoft.EntityFrameworkCore;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Repositories
{
    public class DeliveryZoneRepository : Repository<DeliveryZone>, IDeliveryZoneRepository
    {
        public DeliveryZoneRepository(AppDbContext db) : base(db) { }

        public async Task<IEnumerable<DeliveryZone>> GetActiveZonesAsync()
            => await _set.Where(z => z.IsActive).OrderBy(z => z.Name).ToListAsync();
    }
}
