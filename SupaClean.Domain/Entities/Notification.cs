using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public  class Notification
    {
        public Guid NotificationId { get; private set; }
        public Customer Customer { get; private set; }

        public Guid CustomerId { get; private set; }
        public string Message { get; private set; }
        
        public DateTime SentAt { get;private set;  }

        private Notification() { }

        public Notification(
    Guid customerId,
    string message)
        {
            if (customerId == Guid.Empty)
                throw new BusinessRuleException(
                    "A notification must belong to a customer.");

            if (string.IsNullOrWhiteSpace(message))
                throw new BusinessRuleException(
                    "Notification message is required.");

            NotificationId = Guid.NewGuid();
            CustomerId = customerId;
            Message = message;
            SentAt = DateTime.UtcNow;
        }
    }
}
