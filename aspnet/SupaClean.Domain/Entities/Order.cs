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
        public Guid OrderId { get; private set; }
        public Guid? DeliveryZoneId { get; private set; }
        public Customer Customer { get; private set; }
        public Guid CustomerId { get; private set; }
        public string ? TicketNumber { get; private set; }
        public DateTime OrderDate { get; private set; }

        public DateTime ? ReturnDate { get; private set; }
        public OrderStatus OrderStatus { get; private set; }

        public Fulfillment_Method FulfillmentMethod { get; private set; } = string.Empty;

        public int OrderSequence { get; private set; }                 // set by the database
        public string OrderNumber => $"SC-{OrderSequence}";            // what everyone sees
        public decimal ItemsTotal { get; private set; }
        public string SpecialInstructions { get; private set;  }

        public decimal DeliveryFee { get; private set; }
        public decimal GrandTotal => ItemsTotal + DeliveryFee;
        public string? ExceptionNotes { get; private set; }
        public bool IsFlaggedException { get; private set; }

        public IReadOnlyCollection<OrderItem> OrderItems => _orderItems.AsReadOnly();

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
            OrderStatus = newStatus;
            if (newStatus == OrderStatus.Completed)
            {
                ReturnDate = DateTime.UtcNow;
            }
        }

        public void FlagException(string exceptionNotes)
        {
            if (string.IsNullOrWhiteSpace(exceptionNotes))
                throw new BusinessRuleException("Exception details must be provided when flagging an order.");

            IsFlaggedException = true;
            ExceptionNotes = exceptionNotes.Trim();
            OrderStatus = OrderStatus.IssueFlagged;
        }
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

        private void RecalculateTotal()
        {
            ItemsTotal = _orderItems.Sum(item => item.TotalPrice);
        }
    }


}

