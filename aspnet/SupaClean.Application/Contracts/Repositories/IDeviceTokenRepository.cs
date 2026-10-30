using SupaClean.Domain.Entities;

namespace SupaClean.Application.Contracts.Repositories
{
    public interface IDeviceTokenRepository : IRepository<DeviceToken>
    {
        Task<DeviceToken?> GetByTokenAsync(string token);
        Task<IReadOnlyList<string>> GetTokensForCustomerAsync(Guid customerId);

        // Removes tokens Firebase says no longer work (app uninstalled, etc.).
        Task RemoveByTokensAsync(IEnumerable<string> tokens);
    }
}
