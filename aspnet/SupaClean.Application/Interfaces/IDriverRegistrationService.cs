using SupaClean.Application.DTOs;

namespace SupaClean.Application.Interfaces
{
    public interface IDriverRegistrationService
    {
        // A driver creates their own account. It stays pending until an admin approves it.
        Task RegisterAsync(RegisterDriverDto dto);

        // Drivers waiting for approval, by name.
        Task<IReadOnlyList<PendingDriverDto>> GetPendingAsync();

        // Lets the driver sign in and be given orders.
        Task ApproveAsync(Guid userId);

        // Removes the pending request. The person can sign up again later.
        Task DeclineAsync(Guid userId);
    }
}
