using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Notification
    {
        public Guid NotificationId { get; private set; }
        public Guid CustomerId { get; private set; }
        public Customer Customer { get; private set; } = null!;
        public Guid? OrderId { get; private set; }
        public string Title { get; private set; } = string.Empty;
        public string Message { get; private set; } = string.Empty;
        public bool IsRead { get; private set; }
        public DateTime SentAt { get; private set; }

        private Notification() { }

        public Notification(Guid customerId, string title, string message, Guid? orderId = null)
        {
            if (customerId == Guid.Empty)
                throw new BusinessRuleException("A notification must belong to a customer.");
            if (string.IsNullOrWhiteSpace(title))
                throw new BusinessRuleException("Notification title is required.");
            if (string.IsNullOrWhiteSpace(message))
                throw new BusinessRuleException("Notification message is required.");

            NotificationId = Guid.NewGuid();
            CustomerId = customerId;
            OrderId = orderId;
            Title = title.Trim();
            Message = message.Trim();
            IsRead = false;
            SentAt = DateTime.UtcNow;
        }

        public void MarkAsRead() => IsRead = true;
    }
}
