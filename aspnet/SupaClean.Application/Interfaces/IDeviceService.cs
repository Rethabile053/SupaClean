using SupaClean.Application.DTOs;

namespace SupaClean.Application.Interfaces
{
    public interface IDeviceService
    {
        // Remembers the phone so it receives this customer's push notifications.
        Task RegisterAsync(Guid customerId, RegisterDeviceDto dto);
    }
}
