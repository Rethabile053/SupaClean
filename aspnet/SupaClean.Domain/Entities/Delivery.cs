using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public  class Delivery
    {
        public Guid DeliveryId { get; private set; }
        public Driver Driver { get; private set; }
        public Guid DriverId { get; private set; }
        public Guid OrderId { get; private set; }
        public Order Order { get; private set; } = null!;
        public DateTime? ScheduledFor { get; private set; }
        public DateTime? CompletedAt { get; private set; }
        public DeliveryType DeliveryType { get; private set; }
        public DeliveryStatus DeliveryStatus { get; private set; }

        private Delivery() { }
        public Delivery(
    Guid driverId,
    DeliveryType deliveryType,
     DateTime? scheduledFor = null)
        {
            if (driverId == Guid.Empty)
                throw new BusinessRuleException(
                    "A delivery must be assigned to a driver.");

            DeliveryId = Guid.NewGuid();
            DriverId = driverId;

            DeliveryType = deliveryType;

            DeliveryStatus = DeliveryStatus.Assigned;
        }
        public void MarkCompleted()
        {
            DeliveryStatus = DeliveryStatus.Delivered;   
            CompletedAt = DateTime.UtcNow;
        }
    }
}
