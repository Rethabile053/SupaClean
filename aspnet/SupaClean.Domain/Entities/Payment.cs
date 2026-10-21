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
        public PaymentType PaymentType { get; private set; }
        public decimal Amount { get; private set; }
        public PaymentMethod PaymentMethod { get; private set; }
        public PaymentStatus PaymentStatus { get; private set; }
        public VerificationStatus VerificationStatus { get; private set; }
        public DateTime PaymentDate { get; private set; }
        public string? BankReference { get; private set; }
        public string? ProofOfPayment { get; private set; }
        public string? RejectionReason { get; private set; }
        public Guid? VerifiedByEmployeeId { get; private set; }
        public DateTime? VerifiedAt { get; private set; }
        public decimal? CashReceived { get; private set; }
        public DateTime? CashHandedInAt { get; private set; }

        private Payment() { }

        public Payment(Guid orderId, PaymentType paymentType, decimal amount,
                       PaymentMethod paymentMethod, string? bankReference = null,
                       string? proofOfPayment = null)
        {
            if (orderId == Guid.Empty)
                throw new BusinessRuleException("Payment must be associated with an order.");
            if (amount <= 0)
                throw new BusinessRuleException("Payment amount must be greater than zero.");
            if (paymentType == PaymentType.DeliveryFee && paymentMethod != PaymentMethod.EFT)
                throw new BusinessRuleException("The delivery fee must be paid by EFT before pickup.");
            if (paymentMethod == PaymentMethod.EFT && string.IsNullOrWhiteSpace(proofOfPayment))
                throw new BusinessRuleException("Proof of payment is required for EFT.");

            PaymentId = Guid.NewGuid();
            OrderId = orderId;
            PaymentType = paymentType;
            Amount = amount;
            PaymentMethod = paymentMethod;
            BankReference = bankReference;
            ProofOfPayment = proofOfPayment;
            PaymentDate = DateTime.UtcNow;
            PaymentStatus = PaymentStatus.Due;
            VerificationStatus = VerificationStatus.Pending;
        }

        public void Verify(Guid employeeId)
        {
            EnsureEft();
            if (employeeId == Guid.Empty)
                throw new BusinessRuleException("Verifying employee is required.");
            if (VerificationStatus == VerificationStatus.Verified)
                throw new BusinessRuleException("Payment is already verified.");

            VerificationStatus = VerificationStatus.Verified;
            PaymentStatus = PaymentStatus.Paid;
            VerifiedByEmployeeId = employeeId;
            VerifiedAt = DateTime.UtcNow;
            RejectionReason = null;
        }

        public void RejectProof(string reason)
        {
            EnsureEft();
            if (string.IsNullOrWhiteSpace(reason))
                throw new BusinessRuleException("A reason is required when rejecting proof of payment.");
            if (VerificationStatus == VerificationStatus.Verified)
                throw new BusinessRuleException("A verified payment cannot be rejected.");

            VerificationStatus = VerificationStatus.Declined;
            PaymentStatus = PaymentStatus.Due;
            RejectionReason = reason;
        }

        public void SubmitNewProof(string proofOfPayment)
        {
            EnsureEft();
            if (string.IsNullOrWhiteSpace(proofOfPayment))
                throw new BusinessRuleException("Proof of payment is required.");
            if (VerificationStatus == VerificationStatus.Verified)
                throw new BusinessRuleException("Payment is already verified.");

            ProofOfPayment = proofOfPayment;
            VerificationStatus = VerificationStatus.Pending;
            RejectionReason = null;
        }

        public void MarkCashCollected(Guid driverId, decimal amountReceived)
        {
            if (PaymentMethod != PaymentMethod.CashOnDelivery)
                throw new BusinessRuleException("Only cash on delivery payments can be marked as collected.");
            if (PaymentStatus == PaymentStatus.Paid)
                throw new BusinessRuleException("Payment is already settled.");
            if (amountReceived != Amount)
                throw new BusinessRuleException($"The amount due is R{Amount:0.00}. Collect the full amount before completing the delivery.");

            CashReceived = amountReceived;
            PaymentStatus = PaymentStatus.Paid;
            VerificationStatus = VerificationStatus.Verified;
            VerifiedByEmployeeId = driverId;
            VerifiedAt = DateTime.UtcNow;
        }

        public void ConfirmCashHandedIn(Guid employeeId)
        {
            if (PaymentMethod != PaymentMethod.CashOnDelivery || PaymentStatus != PaymentStatus.Paid)
                throw new BusinessRuleException("Only collected cash payments can be handed in.");
            if (CashHandedInAt is not null)
                throw new BusinessRuleException("This cash has already been handed in.");

            CashHandedInAt = DateTime.UtcNow;
        }

        private void EnsureEft()
        {
            if (PaymentMethod != PaymentMethod.EFT)
                throw new BusinessRuleException("Only EFT payments go through verification.");
        }
    }
}