using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Payment
    {
        public Guid PaymentId { get; private set; }

        public Guid OrderId { get; private set; }
        public Order Order { get; private set; } = null!;
        public decimal Amount { get; private set; }
        public string PaymentMethod { get; private set; } = string.Empty;
       
        public PaymentStatus PaymentStatus { get; private set;  }

        public DateTime PaymentDate { get; private set; }

        public string ? ProofOfPayment { get; private set; }

        public VerificationStatus VerificationStatus { get;private set;  }

        private Payment() { } 

        public Payment(
            Guid orderId,
            decimal amount,
            string paymentMethod,
            string? proofOfPayment = null)
        {
            if (orderId == Guid.Empty)
                throw new BusinessRuleException("Payment must be associated with an order.");

            if (amount <= 0)
                throw new BusinessRuleException("Payment amount must be greater than zero.");

            if (string.IsNullOrWhiteSpace(paymentMethod))
                throw new BusinessRuleException("Payment method is required.");

            PaymentId = Guid.NewGuid();
            OrderId = orderId;
            Amount = amount;
            PaymentMethod = paymentMethod;
            ProofOfPayment = proofOfPayment;
            PaymentDate = DateTime.UtcNow;
            PaymentStatus = PaymentStatus.Due;
            VerificationStatus = VerificationStatus.Pending;
        }

        public void VerifyPayment(bool isApproved)
        {
            if (isApproved)
            {
                VerificationStatus = VerificationStatus.Verified;
                PaymentStatus = PaymentStatus.Paid;
            }
            else
            {
                VerificationStatus = VerificationStatus.Declined;
                PaymentStatus = PaymentStatus.Failed;
            }
        }


    }
}
