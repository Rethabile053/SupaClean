using SupaClean.Application.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Interfaces
{
    public interface IServiceCatalog
    {
        Task<IEnumerable<ServiceDto>> GetActiveServicesAsync();
        Task<IEnumerable<ServiceDto>> GetAllServicesAsync();
        Task SetServiceActiveAsync(Guid serviceId, bool isActive);
        Task UpdateServiceTurnaroundAsync(Guid serviceId, int days);
        Task<Guid> CreateServiceAsync(CreateServiceDto dto);
        Task UpdateServicePriceAsync(Guid serviceId, decimal newPrice);

        // Removes a service nobody has ordered. One that orders use cannot be
        // deleted (the orders would lose their lines): make it inactive instead.
        Task DeleteServiceAsync(Guid serviceId);
    }
}
