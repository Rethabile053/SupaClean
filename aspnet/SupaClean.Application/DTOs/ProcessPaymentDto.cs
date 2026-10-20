using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{

    public record ProcessPaymentDto
           (
      Guid OrderId,
    string PaymentType,          // "DeliveryFee" | "Order"
    string PaymentMethod,        // "Eft" | "CashOnDelivery"
    string? BankReference,
    string? ProofOfPaymentReference
        );

}
