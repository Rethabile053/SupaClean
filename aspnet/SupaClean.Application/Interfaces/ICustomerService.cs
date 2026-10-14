using SupaClean.Application.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Interfaces
{
    public interface ICustomerService
    {
        Task<IEnumerable<ServiceDto>> GetActiveServicesAsync();
        Task<Guid> CreateServiceAsync(CreateServiceDto dto);
        Task UpdateServicePriceAsync(Guid serviceId, decimal newPrice);
    }
}
