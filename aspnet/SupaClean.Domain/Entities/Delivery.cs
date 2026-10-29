using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    // A driver's job for one order: either collecting the laundry from the customer
    // (Collection) or taking the clean laundry back to them (Delivery).
    public  class Delivery
    {
        public Guid DeliveryId { get; private set; }
        public Driver Driver { get; private set; } = null!;
        public Guid DriverId { get; private set; }
        public Guid OrderId { get; private set; }
        public Order Order { get; private set; } = null!;
        public DateTime? ScheduledFor { get; private set; }
        public DateTime? CompletedAt { get; private set; }
        public DeliveryType DeliveryType { get; private set; }
        public DeliveryStatus DeliveryStatus { get; private set; }

        private Delivery() { }
        public Delivery(
    Guid orderId,
    Guid driverId,
    DeliveryType deliveryType,
     DateTime? scheduledFor = null)
        {
            if (orderId == Guid.Empty)
                throw new BusinessRuleException(
                    "A delivery must belong to an order.");
            if (driverId == Guid.Empty)
                throw new BusinessRuleException(
                    "A delivery must be assigned to a driver.");

            DeliveryId = Guid.NewGuid();
            OrderId = orderId;
            DriverId = driverId;
            DeliveryType = deliveryType;
            ScheduledFor = scheduledFor;
            DeliveryStatus = DeliveryStatus.Assigned;
        }

        public bool IsCompleted => CompletedAt is not null;

        // Give the job to another driver, as long as it has not been done.
        public void Reassign(Driver driver)
        {
            if (driver is null || driver.DriverId == Guid.Empty)
                throw new BusinessRuleException(
                    "A delivery must be assigned to a driver.");
            if (IsCompleted)
                throw new BusinessRuleException(
                    "This job is already done, so it cannot be given to another driver.");

            Driver = driver;
            DriverId = driver.DriverId;
        }

        public void MarkCompleted()
        {
            // A collection is "Collected"; a delivery to the customer is "Delivered".
            DeliveryStatus = DeliveryType == DeliveryType.Collection
                ? DeliveryStatus.Collected
                : DeliveryStatus.Delivered;
            CompletedAt = DateTime.UtcNow;
        }
    }
}
