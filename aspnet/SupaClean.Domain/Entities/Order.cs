using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Order
    {
        private readonly List<OrderItem> _orderItems = new();
        private readonly List<OrderStatusChange> _statusHistory = new();
        public Guid OrderId { get; private set; }
        public Guid? DeliveryZoneId { get; private set; }
        public Customer Customer { get; private set; }
        public Guid CustomerId { get; private set; }
        public string ? TicketNumber { get; private set; }
        public DateTime OrderDate { get; private set; }

        public DateTime ? ReturnDate { get; private set; }
        public DateTime? PickupDate { get; private set; }            // when the customer asked us to collect
        public DateTime? DeliveryDate { get; private set; }          // when the customer wants it back (ready by)
        public OrderStatus OrderStatus { get; private set; }

        public Fulfillment_Method FulfillmentMethod { get; private set; }

        public int OrderSequence { get; private set; }                 // set by the database
        public string OrderNumber => $"SC-{OrderSequence}";            // what everyone sees
        public decimal ItemsTotal { get; private set; }
        public string SpecialInstructions { get; private set;  }

        public decimal DeliveryFee { get; private set; }
        public decimal PickupFee { get; private set; }               // 0 unless we collect from the customer's address
        public decimal PointsDiscount { get; private set; }             // rand taken off by redeeming points
        public decimal GrandTotal => ItemsTotal + PickupFee + DeliveryFee - PointsDiscount;
        public decimal OrderPaymentDue => ItemsTotal + PickupFee - PointsDiscount;   // what the order payment covers
        public string? ExceptionNotes { get; private set; }
        public bool IsFlaggedException { get; private set; }

        public IReadOnlyCollection<OrderItem> OrderItems => _orderItems.AsReadOnly();
        public IReadOnlyCollection<OrderStatusChange> StatusHistory => _statusHistory.AsReadOnly();

        private Order() { } 

        public Order(
            Guid customerId,
            Fulfillment_Method fulfillmentMethod,
            string? specialInstructions = null)
        {
            if (customerId == Guid.Empty)
                throw new BusinessRuleException("An order must belong to a valid customer.");

            OrderId = Guid.NewGuid();
            CustomerId = customerId;
            SpecialInstructions = specialInstructions ?? string.Empty;
            OrderDate = DateTime.UtcNow;
            OrderStatus = OrderStatus.PendingInTake;
            ItemsTotal = 0.00m;
            FulfillmentMethod = fulfillmentMethod;
            IsFlaggedException = false;
            RecordStatus();
        }

       
        public void AddOrderItem(Guid serviceId, int quantity, decimal unitPrice, string? description = null)
        {
            var item = new OrderItem(OrderId, serviceId, quantity, unitPrice, description);
            _orderItems.Add(item);
            RecalculateTotal();
        }

        public void LinkPhysicalTicket(string ticketNumber)
        {
            if (string.IsNullOrWhiteSpace(ticketNumber))
                throw new BusinessRuleException("Paper docket ticket number cannot be empty.");

            TicketNumber = ticketNumber;
        }

        public void UpdateStatus(OrderStatus newStatus)
        {
            if (newStatus != OrderStatus)
            {
                OrderStatus = newStatus;
                RecordStatus();
            }
            if (newStatus == OrderStatus.Completed)
            {
                ReturnDate = DateTime.UtcNow;
            }
        }

        // A customer can cancel until we have collected the laundry.
        public bool CanBeCancelled =>
            OrderStatus == OrderStatus.PendingInTake || OrderStatus == OrderStatus.Accepted;

        public void Cancel()
        {
            if (!CanBeCancelled)
                throw new BusinessRuleException(
                    "This order can no longer be cancelled because it is already being processed. Please contact SupaClean.");

            UpdateStatus(OrderStatus.Cancelled);
        }

        public void FlagException(string exceptionNotes)
        {
            if (string.IsNullOrWhiteSpace(exceptionNotes))
                throw new BusinessRuleException("Exception details must be provided when flagging an order.");

            IsFlaggedException = true;
            ExceptionNotes = exceptionNotes.Trim();
            OrderStatus = OrderStatus.IssueFlagged;
            RecordStatus();
        }

        // Remembers when the order reached its current status.
        private void RecordStatus() => _statusHistory.Add(new OrderStatusChange(OrderId, OrderStatus));

        public void SetDeliveryZone(Guid zoneId, decimal fee)
        {
            if (FulfillmentMethod != Fulfillment_Method.Delivery)   
                throw new BusinessRuleException("Only delivery orders have a delivery area.");
            if (zoneId == Guid.Empty)
                throw new BusinessRuleException("A delivery area is required.");
            if (fee <= 0)
                throw new BusinessRuleException("Delivery fee must be greater than zero.");

            DeliveryZoneId = zoneId;
            DeliveryFee = fee;      // snapshot: later price changes won't alter existing orders
        }

        public void SetSchedule(DateTime? pickupDate, DateTime? deliveryDate)
        {
            var pickup = pickupDate is null ? (DateTime?)null : AsUtc(pickupDate.Value);
            var delivery = deliveryDate is null ? (DateTime?)null : AsUtc(deliveryDate.Value);

            if (pickup is not null && delivery is not null && delivery < pickup)
                throw new BusinessRuleException("Delivery cannot be before pickup.");

            PickupDate = pickup;
            DeliveryDate = delivery;
        }

        // Postgres "timestamp with time zone" only accepts UTC values.
        private static DateTime AsUtc(DateTime value) => value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
        };

        public void SetHomePickup(decimal fee)
        {
            if (fee <= 0)
                throw new BusinessRuleException("Pickup fee must be greater than zero.");

            PickupFee = fee;        // snapshot, like the delivery fee
        }

        // Whole rands only, and never more than the laundry itself, so the order payment stays above zero.
        public void ApplyPointsDiscount(decimal rand)
        {
            if (rand <= 0)
                throw new BusinessRuleException("The points discount must be more than zero.");
            if (rand != Math.Floor(rand))
                throw new BusinessRuleException("The points discount must be in whole rands.");
            if (rand >= ItemsTotal)
                throw new BusinessRuleException("The points discount cannot cover the whole order.");

            PointsDiscount = rand;
        }

        private void RecalculateTotal()
        {
            ItemsTotal = _orderItems.Sum(item => item.TotalPrice);
        }
    }


}

