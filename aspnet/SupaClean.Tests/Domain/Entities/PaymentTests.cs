using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Tests.Domain.Entities
{
    [TestClass]
    public class PaymentTests
    {
        private static Payment NewEft() =>
            new(Guid.NewGuid(), PaymentType.Orderpayment, 250.00m, PaymentMethod.EFT, "REF123", "proofs/receipt.pdf");

        private static Payment NewCash() =>
            new(Guid.NewGuid(), PaymentType.Orderpayment, 250.00m, PaymentMethod.CashOnDelivery);

        [TestMethod]
        public void Create_WithZeroAmount_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() =>
                new Payment(Guid.NewGuid(), PaymentType.Orderpayment, 0m, PaymentMethod.CashOnDelivery));

        [TestMethod]
        public void Create_EftWithoutProof_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() =>
                new Payment(Guid.NewGuid(), PaymentType.Orderpayment, 250m, PaymentMethod.EFT));

        [TestMethod]
        public void Create_DeliveryFeeByCash_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() =>
                new Payment(Guid.NewGuid(), PaymentType.DeliveryFee, 60m, PaymentMethod.CashOnDelivery));

        [TestMethod]
        public void Verify_ShouldSetVerifiedAndPaid()
        {
            var payment = NewEft();
            var employeeId = Guid.NewGuid();

            payment.Verify(employeeId);

            Assert.AreEqual(VerificationStatus.Verified, payment.VerificationStatus);
            Assert.AreEqual(PaymentStatus.Paid, payment.PaymentStatus);
            Assert.AreEqual(employeeId, payment.VerifiedByEmployeeId);
            Assert.IsNotNull(payment.VerifiedAt);
        }

        [TestMethod]
        public void Verify_Twice_ShouldThrow()
        {
            var payment = NewEft();
            payment.Verify(Guid.NewGuid());
            Assert.ThrowsExactly<BusinessRuleException>(() => payment.Verify(Guid.NewGuid()));
        }

        [TestMethod]
        public void RejectProof_ShouldSetDeclinedAndKeepPaymentDue()
        {
            var payment = NewEft();

            payment.RejectProof("Amount does not match");

            Assert.AreEqual(VerificationStatus.Declined, payment.VerificationStatus);
            Assert.AreEqual(PaymentStatus.Due, payment.PaymentStatus);
            Assert.AreEqual("Amount does not match", payment.RejectionReason);
        }

        [TestMethod]
        public void RejectProof_WithoutReason_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() => NewEft().RejectProof("  "));

        [TestMethod]
        public void SubmitNewProof_AfterRejection_ShouldResetToPending()
        {
            var payment = NewEft();
            payment.RejectProof("Unreadable");

            payment.SubmitNewProof("proofs/new.pdf");

            Assert.AreEqual(VerificationStatus.Pending, payment.VerificationStatus);
            Assert.IsNull(payment.RejectionReason);
        }

        [TestMethod]
        public void MarkCashCollected_WithWrongAmount_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() =>
                NewCash().MarkCashCollected(Guid.NewGuid(), 200m));

        [TestMethod]
        public void MarkCashCollected_WithFullAmount_ShouldSetPaid()
        {
            var payment = NewCash();

            payment.MarkCashCollected(Guid.NewGuid(), 250m);

            Assert.AreEqual(PaymentStatus.Paid, payment.PaymentStatus);
            Assert.AreEqual(250m, payment.CashReceived);
        }

        [TestMethod]
        public void Verify_OnCashPayment_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() => NewCash().Verify(Guid.NewGuid()));
    }
}
    

