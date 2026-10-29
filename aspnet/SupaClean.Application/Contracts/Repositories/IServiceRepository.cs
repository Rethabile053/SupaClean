using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Contracts.Repositories
{
    public  interface IServiceRepository : IRepository<Service>
    {
        Task<IEnumerable<Service>> GetActiveServicesAsync();

        // True when any order has a line for this service.
        Task<bool> IsUsedByOrdersAsync(Guid serviceId);
    }
}
