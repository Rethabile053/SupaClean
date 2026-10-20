using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Contracts.Repositories
{
    public interface IDeliveryZoneRepository : IRepository<DeliveryZone>
    {
        Task<IEnumerable<DeliveryZone>> GetActiveZonesAsync();
    }
}
