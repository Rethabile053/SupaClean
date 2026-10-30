using SupaClean.Domain.Entities;

namespace SupaClean.Application.Contracts.Repositories
{
    public interface IDriverRepository : IRepository<Driver>
    {
        Task<Driver?> GetByUserIdAsync(Guid userId);

        // The driver record for a user who has the Driver role. The first time a
        // driver is given a job, their Employee and Driver rows are created. They
        // are added to the context and saved with the next SaveChanges.
        Task<Driver> GetOrCreateForUserAsync(User user, string? licenseNumber = null);
    }
}
