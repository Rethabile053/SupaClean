using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record PaymentDto
    (
     Guid PaymentId,
    Guid OrderId,
    decimal Amount,
    string PaymentMethod,
    string PaymentStatus,
    string VerificationStatus,
    string? ProofOfPayment,
    string? RejectionReason,
    DateTime PaymentDate,
    DateTime? VerifiedAt
      );
}
