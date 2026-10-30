using SupaClean.Application.DTOs;

namespace SupaClean.Application.Interfaces
{
    public interface IDriverAssignmentService
    {
        // Everyone with the Driver role.
        Task<IReadOnlyList<DriverOptionDto>> GetDriversAsync();

        // Orders that need a driver now (ready for collection, or out for delivery).
        Task<IReadOnlyList<AssignableStopDto>> GetStopsAsync();

        // Give the order's current job to this driver, or move it from another driver.
        Task AssignAsync(Guid orderId, Guid driverUserId);

        // Take the job away from its driver. Refused once the driver has started it.
        Task UnassignAsync(Guid orderId);
    }
}
