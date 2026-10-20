using SupaClean.Application.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Interfaces
{
    public interface IDeliveryZoneService
    {
        Task<IEnumerable<DeliveryZoneDto>> GetActiveZonesAsync();
        Task<IEnumerable<DeliveryZoneDto>> GetAllZonesAsync();
        Task UpdateZoneFeeAsync(Guid zoneId, decimal fee);
        Task SetZoneActiveAsync(Guid zoneId, bool isActive);
    }
}
