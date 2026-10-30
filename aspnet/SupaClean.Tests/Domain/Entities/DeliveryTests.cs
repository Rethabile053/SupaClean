using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Tests.Domain.Entities
{
    [TestClass]
    public class DeliveryTests
    {
        private static Driver NewDriver()
            => new(Guid.NewGuid(), password: "", email: "d@example.com", licenseNumber: "L-1");

        [TestMethod]
        public void New_ShouldBelongToTheOrderAndDriverAndStartAssigned()
        {
            var order = Guid.NewGuid();
            var driver = Guid.NewGuid();

            var job = new Delivery(order, driver, DeliveryType.Delivery);

            Assert.AreEqual(order, job.OrderId);   // was never set before
            Assert.AreEqual(driver, job.DriverId);
            Assert.AreEqual(DeliveryStatus.Assigned, job.DeliveryStatus);
            Assert.IsFalse(job.IsCompleted);
        }

        [TestMethod]
        public void New_WithoutAnOrderOrDriver_ShouldBeRefused()
        {
            Assert.ThrowsExactly<BusinessRuleException>(
                () => new Delivery(Guid.Empty, Guid.NewGuid(), DeliveryType.Delivery));
            Assert.ThrowsExactly<BusinessRuleException>(
                () => new Delivery(Guid.NewGuid(), Guid.Empty, DeliveryType.Delivery));
        }

        [TestMethod]
        public void Reassign_ShouldMoveTheJobToTheOtherDriver()
        {
            var job = new Delivery(Guid.NewGuid(), Guid.NewGuid(), DeliveryType.Collection);
            var other = NewDriver();

            job.Reassign(other);

            Assert.AreEqual(other.DriverId, job.DriverId);
            Assert.AreSame(other, job.Driver);
        }

        [TestMethod]
        public void Reassign_ADoneJob_ShouldBeRefused()
        {
            var job = new Delivery(Guid.NewGuid(), Guid.NewGuid(), DeliveryType.Delivery);
            job.MarkCompleted();

            Assert.ThrowsExactly<BusinessRuleException>(() => job.Reassign(NewDriver()));
        }

        [TestMethod]
        public void MarkCompleted_ShouldSayCollectedForACollectionAndDeliveredForADelivery()
        {
            var collection = new Delivery(Guid.NewGuid(), Guid.NewGuid(), DeliveryType.Collection);
            var delivery = new Delivery(Guid.NewGuid(), Guid.NewGuid(), DeliveryType.Delivery);

            collection.MarkCompleted();
            delivery.MarkCompleted();

            Assert.AreEqual(DeliveryStatus.Collected, collection.DeliveryStatus);
            Assert.AreEqual(DeliveryStatus.Delivered, delivery.DeliveryStatus);
            Assert.IsTrue(collection.IsCompleted);
            Assert.IsTrue(delivery.IsCompleted);
        }
    }
}
