using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Contracts.Repositories
{
    public interface IPayment : IRepository<Payment>
    {
       
        Task<IEnumerable<Payment>> GetUnverifiedPaymentsAsync();
        Task<Payment?> GetByOrderIdAndTypeAsync(Guid orderId, PaymentType type);
        Task<IEnumerable<Payment>> GetAllWithDetailsAsync();
        Task<IEnumerable<Payment>> GetByOrderIdAsync(Guid orderId);
    }
}
