using SupaClean.Application.Contracts;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Services
{
    public class NotificationService : INotificationService
    {
        private readonly INotificationRepository _notifications;
        private readonly IUnitOfWork _unitOfWork;

        public NotificationService(INotificationRepository notifications, IUnitOfWork unitOfWork)
        {
            _notifications = notifications;
            _unitOfWork = unitOfWork;
        }

        public async Task<IEnumerable<NotificationDto>> GetCustomerNotificationsAsync(Guid customerId)
            => (await _notifications.GetByCustomerIdAsync(customerId)).Select(MapToDto);

        public async Task MarkAsReadAsync(Guid customerId, Guid notificationId)
        {
            var n = await _notifications.GetByIdAsync(notificationId);
            if (n is null || n.CustomerId != customerId)
                throw new KeyNotFoundException("Notification not found.");   // don't reveal other customers' data

            n.MarkAsRead();
            await _notifications.Update(n);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task MarkAllAsReadAsync(Guid customerId)
        {
            var unread = (await _notifications.GetByCustomerIdAsync(customerId))
                         .Where(n => !n.IsRead).ToList();
            foreach (var n in unread) n.MarkAsRead();
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task DeleteAsync(Guid customerId, Guid notificationId)
        {
            var n = await _notifications.GetByIdAsync(notificationId);
            if (n is null || n.CustomerId != customerId)
                throw new KeyNotFoundException("Notification not found.");   // don't reveal other customers' data

            await _notifications.Delete(n);
            await _unitOfWork.SaveChangesAsync();
        }

        private static NotificationDto MapToDto(Notification n)
            => new(n.NotificationId, n.Title, n.Message, n.OrderId, n.IsRead, n.SentAt);
    }

}
