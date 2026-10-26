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
        Task<IEnumerable<DriverStopDto>> GetStopsAsync();
        Task MarkCollectedAsync(Guid orderId);
        Task RecordCashCollectedAsync(Guid orderId, Guid driverId, decimal amount);
        Task MarkDeliveredAsync(Guid orderId);
    }
}
