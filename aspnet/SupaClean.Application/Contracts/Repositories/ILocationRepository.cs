using SupaClean.Domain.Entities;

namespace SupaClean.Application.Contracts.Repositories
{
    // Every address the app uses: customers' addresses and the depots.
    public interface ILocationRepository
    {
        // The saved location with this street address and city, ignoring capital letters.
        Task<Location?> FindAsync(string addressLine1, string city);

        // Added to the context and saved with the next SaveChanges.
        Task AddAsync(Location location);
    }
}
