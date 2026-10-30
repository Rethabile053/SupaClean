using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Tests.Domain.Entities
{
    [TestClass]
    public class OrderTests
    {
        private static Order NewDeliveryOrder() => new(Guid.NewGuid(), Fulfillment_Method.Delivery);

        [TestMethod]
        public void Create_WithEmptyCustomerId_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() =>
                new Order(Guid.Empty, Fulfillment_Method.Delivery));

        [TestMethod]
        public void AddOrderItem_ShouldRecalculateItemsTotal()
        {
            var order = NewDeliveryOrder();

            order.AddOrderItem(Guid.NewGuid(), quantity: 2, unitPrice: 150.00m);
            order.AddOrderItem(Guid.NewGuid(), quantity: 1, unitPrice: 100.00m);

            Assert.AreEqual(400.00m, order.ItemsTotal);
            Assert.AreEqual(2, order.OrderItems.Count);
        }

        [TestMethod]
        public void SetDeliveryZone_ShouldSetFeeAndGrandTotal()
        {
            var order = NewDeliveryOrder();
            order.AddOrderItem(Guid.NewGuid(), 1, 100m);

            order.SetDeliveryZone(Guid.NewGuid(), 60m);

            Assert.AreEqual(60m, order.DeliveryFee);
            Assert.AreEqual(160m, order.GrandTotal);
        }

        [TestMethod]
        public void SetHomePickup_ShouldAddPickupFeeToGrandTotal()
        {
            var order = NewDeliveryOrder();
            order.AddOrderItem(Guid.NewGuid(), 1, 100m);
            order.SetDeliveryZone(Guid.NewGuid(), 50m);

            order.SetHomePickup(50m);

            Assert.AreEqual(50m, order.PickupFee);
            Assert.AreEqual(200m, order.GrandTotal);
        }

        [TestMethod]
        public void SetHomePickup_WithZeroFee_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() =>
                NewDeliveryOrder().SetHomePickup(0m));

        [TestMethod]
        public void SetSchedule_ShouldKeepBothDatesAsUtc()
        {
            var order = NewDeliveryOrder();
            var pickup = new DateTime(2026, 11, 2, 8, 0, 0, DateTimeKind.Utc);
            var delivery = new DateTime(2026, 11, 5, 14, 0, 0, DateTimeKind.Unspecified);

            order.SetSchedule(pickup, delivery);

            Assert.AreEqual(pickup, order.PickupDate);
            Assert.AreEqual(DateTimeKind.Utc, order.DeliveryDate!.Value.Kind);
            Assert.AreEqual(14, order.DeliveryDate.Value.Hour);
        }

        [TestMethod]
        public void SetSchedule_WithNoDates_ShouldLeaveThemEmpty()
        {
            var order = NewDeliveryOrder();

            order.SetSchedule(null, null);

            Assert.IsNull(order.PickupDate);
            Assert.IsNull(order.DeliveryDate);
        }

        [TestMethod]
        public void SetSchedule_WithDeliveryBeforePickup_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() =>
                NewDeliveryOrder().SetSchedule(
                    new DateTime(2026, 11, 5, 8, 0, 0, DateTimeKind.Utc),
                    new DateTime(2026, 11, 4, 8, 0, 0, DateTimeKind.Utc)));

        [TestMethod]
        public void SetDeliveryZone_WithZeroFee_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() =>
                NewDeliveryOrder().SetDeliveryZone(Guid.NewGuid(), 0m));

        [TestMethod]
        public void LinkPhysicalTicket_WithValidDocket_ShouldSetTicketNumber()
        {
            var order = NewDeliveryOrder();
            order.LinkPhysicalTicket("T-80921");
            Assert.AreEqual("T-80921", order.TicketNumber);
        }

        [TestMethod]
        public void LinkPhysicalTicket_WithEmptyString_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() => NewDeliveryOrder().LinkPhysicalTicket("   "));

        [TestMethod]
        public void UpdateStatus_ToCompleted_ShouldSetReturnDate()
        {
            var order = NewDeliveryOrder();
            order.UpdateStatus(OrderStatus.Completed);

            Assert.AreEqual(OrderStatus.Completed, order.OrderStatus);
            Assert.IsNotNull(order.ReturnDate);
        }

        [TestMethod]
        public void FlagException_ShouldFlagOrder()
        {
            var order = NewDeliveryOrder();
            order.FlagException("Difficult stain on jacket");

            Assert.IsTrue(order.IsFlaggedException);
            Assert.AreEqual(OrderStatus.IssueFlagged, order.OrderStatus);
        }

        [TestMethod]
        public void NewOrder_ShouldStartItsStatusHistoryAtPendingInTake()
        {
            var history = NewDeliveryOrder().StatusHistory.ToList();

            Assert.AreEqual(1, history.Count);
            Assert.AreEqual(OrderStatus.PendingInTake, history[0].Status);
        }

        [TestMethod]
        public void UpdateStatus_ShouldRecordWhenEachStatusWasReached()
        {
            var order = NewDeliveryOrder();
            order.UpdateStatus(OrderStatus.Washing);
            order.UpdateStatus(OrderStatus.Completed);

            CollectionAssert.AreEqual(
                new[] { OrderStatus.PendingInTake, OrderStatus.Washing, OrderStatus.Completed },
                order.StatusHistory.Select(c => c.Status).ToArray());
        }

        [TestMethod]
        public void UpdateStatus_ToTheSameStatus_ShouldNotAddAnotherEntry()
        {
            var order = NewDeliveryOrder();
            order.UpdateStatus(OrderStatus.Washing);
            order.UpdateStatus(OrderStatus.Washing);

            Assert.AreEqual(2, order.StatusHistory.Count);
        }

        [TestMethod]
        public void FlagException_ShouldRecordTheStatusChange()
        {
            var order = NewDeliveryOrder();
            order.FlagException("Difficult stain on jacket");

            Assert.AreEqual(OrderStatus.IssueFlagged, order.StatusHistory.Last().Status);
        }

        [TestMethod]
        public void Cancel_ANewOrder_ShouldCancelAndRecordIt()
        {
            var order = NewDeliveryOrder();
            order.Cancel();

            Assert.AreEqual(OrderStatus.Cancelled, order.OrderStatus);
            Assert.AreEqual(OrderStatus.Cancelled, order.StatusHistory.Last().Status);
        }

        [TestMethod]
        public void Cancel_AnAcceptedOrder_ShouldCancel()
        {
            var order = NewDeliveryOrder();
            order.UpdateStatus(OrderStatus.Accepted);
            order.Cancel();

            Assert.AreEqual(OrderStatus.Cancelled, order.OrderStatus);
        }

        [TestMethod]
        public void Cancel_AfterCollection_ShouldThrow()
        {
            var order = NewDeliveryOrder();
            order.UpdateStatus(OrderStatus.Collected);

            Assert.IsFalse(order.CanBeCancelled);
            Assert.ThrowsExactly<BusinessRuleException>(() => order.Cancel());
            Assert.AreEqual(OrderStatus.Collected, order.OrderStatus);
        }

        [TestMethod]
        public void Cancel_AnAlreadyCancelledOrder_ShouldThrow()
        {
            var order = NewDeliveryOrder();
            order.Cancel();

            Assert.ThrowsExactly<BusinessRuleException>(() => order.Cancel());
        }
    }
}
