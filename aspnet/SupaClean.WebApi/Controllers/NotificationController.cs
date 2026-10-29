using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.WebApi.Extensions;
using SupaClean.Domain.Entities;

namespace SupaClean.WebApi.Controllers
{

    [ApiController]
    [Route("api/v1/notifications")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _notifications;
        private readonly ICustomerService _customers;

        public NotificationsController(INotificationService notifications, ICustomerService customers)
        {
            _notifications = notifications;
            _customers = customers;
        }

        private async Task<Guid> CurrentCustomerIdAsync()
            => (await _customers.GetCustomerByUserIdAsync(User.GetUserId())
                ?? throw new KeyNotFoundException("Customer profile not found.")).CustomerId;

        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<NotificationDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<NotificationDto>>> GetMine()
            => Ok(await _notifications.GetCustomerNotificationsAsync(await CurrentCustomerIdAsync()));

        [HttpPost("{id:guid}/read")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> MarkRead(Guid id)
        {
            await _notifications.MarkAsReadAsync(await CurrentCustomerIdAsync(), id);
            return NoContent();
        }

        [HttpPost("read-all")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> MarkAllRead()
        {
            await _notifications.MarkAllAsReadAsync(await CurrentCustomerIdAsync());
            return NoContent();
        }

        // A customer removes one of their own notifications.
        [HttpDelete("{id:guid}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> Delete(Guid id)
        {
            await _notifications.DeleteAsync(await CurrentCustomerIdAsync(), id);
            return NoContent();
        }
    }
}
