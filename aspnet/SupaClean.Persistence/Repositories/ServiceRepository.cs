using SupaClean.Application.Contracts.Repositories;
using Microsoft.EntityFrameworkCore;
using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Repositories
{
    public class ServiceRepository : Repository<Service>, IServiceRepository
    {
        public ServiceRepository(AppDbContext db) : base(db) { }

        public async Task<IEnumerable<Service>> GetActiveServicesAsync()
            => await _set.Where(s => s.IsActive).ToListAsync();   // rename IsActive to match Service.cs
    }
}
