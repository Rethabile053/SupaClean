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
        public Customer Customer { get; private set; }
        public Guid CustomerId { get; private set; }
        public string ? TicketNumber { get; private set; }
        public DateTime OrderDate { get; private set; }

        public DateTime ? ReturnDate { get; private set; }
        public OrderStatus OrderStatus { get; private set; }

        public Fulfillment_Method FulfillmentMethod { get; private set; }

        public decimal TotalAmount { get; private set; }
        public string SpecialInstructions { get; private set;  }
        public string? ExceptionNotes { get; private set; }
        public bool IsFlaggedException { get; private set; }

        public IReadOnlyCollection<OrderItem> OrderItems => _orderItems.AsReadOnly();

        private Order() { } 

        public Order(
            Guid customerId,
            string? specialInstructions = null)
        {
            if (customerId == Guid.Empty)
                throw new BusinessRuleException("An order must belong to a valid customer.");

            OrderId = Guid.NewGuid();
            CustomerId = customerId;
            SpecialInstructions = specialInstructions;
            OrderDate = DateTime.UtcNow;
            OrderStatus = OrderStatus.PendingInTake;
            TotalAmount = 0.00m;
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

        private void RecalculateTotal()
        {
            TotalAmount = _orderItems.Sum(item => item.TotalPrice);
        }
    }


}

