using SupaClean.Domain.Enums;
using System;

namespace SupaClean.Domain.Entities
{
    /// <summary>
    /// One row each time an order moves to a new status, so the customer can see
    /// when every stage of their order happened.
    /// </summary>
    public class OrderStatusChange
    {
        public int Id { get; private set; }                  // set by the database
        public Guid OrderId { get; private set; }
        public OrderStatus Status { get; private set; }
        public DateTime ChangedAt { get; private set; }      // UTC

        private OrderStatusChange() { }

        public OrderStatusChange(Guid orderId, OrderStatus status)
        {
            OrderId = orderId;
            Status = status;
            ChangedAt = DateTime.UtcNow;
        }
    }
}
