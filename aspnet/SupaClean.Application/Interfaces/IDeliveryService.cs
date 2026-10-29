using SupaClean.Application.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Interfaces
{
    public interface IDeliveryService
    {
        // The orders that need a driver. With a driver's user id, only the ones
        // an admin has given to that driver; without one, all of them.
        Task<IEnumerable<DriverStopDto>> GetStopsAsync(Guid? driverUserId = null);
        Task MarkCollectedAsync(Guid orderId);
        Task RecordCashCollectedAsync(Guid orderId, Guid driverId, decimal amount);
        Task MarkDeliveredAsync(Guid orderId);
    }
}
