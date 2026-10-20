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
        [TestMethod]
        public void CreatePayment_WithZeroAmount_ShouldThrowBusinessRuleException()
        {
            // Act & Assert
            Assert.ThrowsExactly<BusinessRuleException>(() =>
                new Payment(Guid.NewGuid(), amount: 0.00m, paymentMethod: "Cash")
            );
        }

        [TestMethod]
        public void VerifyPayment_WhenApproved_ShouldSetStatusToVerifiedAndCompleted()
        {
            // Arrange
            var payment = new Payment(Guid.NewGuid(), amount: 250.00m, paymentMethod: "Card");

            // Act
            payment.VerifyPayment(isApproved: true);

            // Assert
            Assert.AreEqual(VerificationStatus.Verified, payment.VerificationStatus);
            Assert.AreEqual(PaymentStatus.Paid, payment.PaymentStatus);
        }

        [TestMethod]
        public void VerifyPayment_WhenRejected_ShouldSetStatusToRejectedAndFailed()
        {
            // Arrange
            var payment = new Payment(Guid.NewGuid(), amount: 250.00m, paymentMethod: "EFT");

            // Act
            payment.VerifyPayment(isApproved: false);

            // Assert
            Assert.AreEqual(VerificationStatus.Declined, payment.VerificationStatus);
            Assert.AreEqual(PaymentStatus.Failed, payment.PaymentStatus);
        }
    }
}
    

