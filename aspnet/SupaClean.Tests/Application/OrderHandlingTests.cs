using SupaClean.Application.Services;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;

namespace SupaClean.Tests.Application
{
    [TestClass]
    public class OrderHandlingTests
    {
        // The instructions text the app writes for an order.
        private static string Instructions(string pickup, string delivery)
            => $"Pickup ({pickup}): 31/10/2026 08:00-10:00 | Delivery ({delivery}): 02/11/2026 14:00-16:00 | Address: 12 Main Road, Bloemfontein";

        private static Order NewOrder(Fulfillment_Method method, bool homePickup, string instructions)
        {
            var order = new Order(Guid.NewGuid(), method, instructions);
            if (homePickup) order.SetHomePickup(50m);
            return order;
        }

        [TestMethod]
        public void HomePickupAndHomeDelivery()
        {
            var order = NewOrder(Fulfillment_Method.Delivery, true,
                Instructions("At my address", "Deliver to me"));

            Assert.AreEqual("Home pickup", OrderHandling.PickupMethod(order));
            Assert.AreEqual("Home delivery", OrderHandling.ReturnMethod(order));
        }

        [TestMethod]
        public void DropOffAtADepot_NamesTheDepot()
        {
            var order = NewOrder(Fulfillment_Method.Delivery, false,
                Instructions("Drop off at depot: Bloemfontein Central", "Deliver to me"));

            Assert.AreEqual("Drop-off at depot: Bloemfontein Central", OrderHandling.PickupMethod(order));
            Assert.AreEqual("Home delivery", OrderHandling.ReturnMethod(order));
        }

        [TestMethod]
        public void CollectingAtADepot_NamesTheDepot()
        {
            var order = NewOrder(Fulfillment_Method.DropOff, true,
                Instructions("At my address", "Collect at depot: Botshabelo Depot"));

            Assert.AreEqual("Home pickup", OrderHandling.PickupMethod(order));
            Assert.AreEqual("Collect at depot: Botshabelo Depot", OrderHandling.ReturnMethod(order));
        }

        [TestMethod]
        public void DropOffAndCollectAtDepots_BothNamed()
        {
            var order = NewOrder(Fulfillment_Method.DropOff, false,
                Instructions("Drop off at depot: Thaba Nchu Depot", "Collect at depot: Bloemfontein Central"));

            Assert.AreEqual("Drop-off at depot: Thaba Nchu Depot", OrderHandling.PickupMethod(order));
            Assert.AreEqual("Collect at depot: Bloemfontein Central", OrderHandling.ReturnMethod(order));
        }

        [TestMethod]
        public void AnOrderWithNoInstructions_StillSaysWhichKind()
        {
            var order = NewOrder(Fulfillment_Method.DropOff, false, string.Empty);

            Assert.AreEqual("Drop-off at depot", OrderHandling.PickupMethod(order));
            Assert.AreEqual("Collect at depot", OrderHandling.ReturnMethod(order));
        }

        [TestMethod]
        public void ADepotChosenButNotNamed_StillSaysWhichKind()
        {
            var order = NewOrder(Fulfillment_Method.DropOff, false,
                Instructions("Drop off at depot", "Collect at depot"));

            Assert.AreEqual("Drop-off at depot", OrderHandling.PickupMethod(order));
            Assert.AreEqual("Collect at depot", OrderHandling.ReturnMethod(order));
        }

        [TestMethod]
        public void TheOtherPartsOfTheInstructions_AreNotMistakenForADepot()
        {
            // A customer's own note that mentions depots must not change the answer.
            var order = NewOrder(Fulfillment_Method.Delivery, true,
                Instructions("At my address", "Deliver to me") + " | Notes: Drop off at depot please");

            Assert.AreEqual("Home pickup", OrderHandling.PickupMethod(order));
            Assert.AreEqual("Home delivery", OrderHandling.ReturnMethod(order));
        }
    }
}
