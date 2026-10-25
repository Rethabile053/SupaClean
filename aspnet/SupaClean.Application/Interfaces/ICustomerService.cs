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
        Task<CustomerDto?> GetCustomerByIdAsync(Guid customerId);
        Task<CustomerDto?> GetCustomerByUserIdAsync(Guid userId);
        Task<Guid> RegisterCustomerAsync(Guid userId, CreateCustomerDto dto);
        Task UpdateCustomerProfileAsync(Guid userId, UpdateCustomerDto dto);
        Task<IEnumerable<CustomerDto>> GetAllCustomersAsync();
        Task<IEnumerable<CustomerDto>> SearchCustomersAsync(string? search);
    }
}
