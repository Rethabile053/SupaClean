using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class OrderItem
    {
        public Guid OrderItemId { get; private set; }
        public Guid ServiceId { get; private set; }
        public Guid OrderId { get; private set; }
        public Service Service { get; private set; }

        public Order Order { get; private set; }
        public string? Description { get; private set; }
        public decimal UnitPrice { get; private set; }

        public int Quantity { get; private set; }
        public decimal TotalPrice { get; private set; }

        private OrderItem() { }

        public OrderItem(Guid orderId, Guid serviceId, int quantity, decimal unitPrice, string? description = null)
        {
            if (orderId == Guid.Empty)
                throw new BusinessRuleException("Order item must be linked to an order.");

            if (serviceId == Guid.Empty)
                throw new BusinessRuleException("Order item must specify a valid service.");

            if (quantity <= 0)
                throw new BusinessRuleException("Quantity must be at least 1.");

            if (unitPrice < 0)
                throw new BusinessRuleException("Unit price cannot be negative.");

            OrderItemId = Guid.NewGuid();
            OrderId = orderId;
            ServiceId = serviceId;
            Quantity = quantity;
            UnitPrice = unitPrice;
            TotalPrice = quantity * unitPrice;
            Description = description?.Trim();
        }
    }
   
}
