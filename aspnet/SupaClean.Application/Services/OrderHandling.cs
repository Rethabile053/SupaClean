using System.Text.RegularExpressions;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;

namespace SupaClean.Application.Services
{
    // How the customer chose to hand over and get back their laundry, in words.
    // Both choices are made in the app and arrive with the order:
    //   pickup:  "At my address" (we collect, so a pickup fee is charged)
    //            or "Drop off at depot" (the customer brings it, no pickup fee)
    //   return:  "Deliver to me" (the order is a Delivery)
    //            or "Collect at depot" (the order is a DropOff)
    // The depot's name is in the order's instructions, which the app writes as
    // "Pickup (Drop off at depot: Name): ... | Delivery (Collect at depot: Name): ...".
    public static class OrderHandling
    {
        public const string HomePickup = "Home pickup";
        public const string DropOffAtDepot = "Drop-off at depot";
        public const string HomeDelivery = "Home delivery";
        public const string CollectAtDepot = "Collect at depot";

        private static readonly Regex PickupDepot = new(
            @"Pickup \(Drop off at depot(?::\s*(?<name>[^)]*))?\)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex ReturnDepot = new(
            @"Delivery \(Collect at depot(?::\s*(?<name>[^)]*))?\)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        // How the laundry gets to us.
        public static string PickupMethod(Order order)
            => order.PickupFee > 0
                ? HomePickup
                : WithDepot(DropOffAtDepot, PickupDepot, order.SpecialInstructions);

        // How the laundry gets back to the customer.
        public static string ReturnMethod(Order order)
            => order.FulfillmentMethod == Fulfillment_Method.Delivery
                ? HomeDelivery
                : WithDepot(CollectAtDepot, ReturnDepot, order.SpecialInstructions);

        private static string WithDepot(string label, Regex pattern, string? instructions)
        {
            var name = pattern.Match(instructions ?? string.Empty).Groups["name"].Value.Trim();
            return name.Length == 0 ? label : $"{label}: {name}";
        }
    }
}
