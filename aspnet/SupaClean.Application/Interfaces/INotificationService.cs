using SupaClean.Application.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Interfaces
{
    public interface INotificationService
    {
        Task<IEnumerable<NotificationDto>> GetCustomerNotificationsAsync(Guid customerId);
        Task MarkAsReadAsync(Guid customerId, Guid notificationId);
        Task MarkAllAsReadAsync(Guid customerId);
    }
}
