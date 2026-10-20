using SupaClean.Application.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Interfaces
{
    public interface IPaymentService
    {
        Task<Guid> ProcessPaymentAsync(ProcessPaymentDto dto);
        Task VerifyPaymentAsync(Guid paymentId, Guid verifiedByEmployeeId);
        Task RequestNewProofOfPaymentAsync(Guid paymentId, string reason);
        Task<IEnumerable<PaymentDto>> GetPaymentsByOrderIdAsync(Guid orderId);
        Task<IEnumerable<PaymentDto>> GetUnverifiedPaymentsAsync();
        Task SubmitNewProofAsync(Guid paymentId, string proofOfPayment);
    }
}
