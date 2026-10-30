using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record PaymentReviewDto(
     Guid PaymentId, Guid OrderId, string OrderNumber, string CustomerName,
     string PaymentType, string PaymentMethod, string PaymentStatus, string VerificationStatus,
     decimal AmountDue, string? BankReference, string? RejectionReason,
     DateTime SubmittedAt, bool HasProof);
}
