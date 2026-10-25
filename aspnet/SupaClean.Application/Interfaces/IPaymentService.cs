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
        Task VerifyPaymentAsync(Guid paymentId, Guid verifiedByEmployeeId, decimal confirmedAmount);
        Task RequestNewProofOfPaymentAsync(Guid paymentId, string reason);
        Task<IEnumerable<PaymentDto>> GetPaymentsByOrderIdAsync(Guid orderId);
        Task SubmitNewProofAsync(Guid paymentId, string proofOfPayment);
        Task<IEnumerable<PaymentReviewDto>> GetPaymentsForReviewAsync();
        Task<IEnumerable<PaymentReviewDto>> GetAllPaymentsAsync(string? search, string? type, string? method, string? verification);
        Task<string> GetProofUrlAsync(Guid paymentId);
    }
}
