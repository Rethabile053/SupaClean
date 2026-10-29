using Microsoft.EntityFrameworkCore;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Domain.Entities;

namespace SupaClean.Persistence.Repositories
{
    public class DeviceTokenRepository : Repository<DeviceToken>, IDeviceTokenRepository
    {
        public DeviceTokenRepository(AppDbContext db) : base(db) { }

        public Task<DeviceToken?> GetByTokenAsync(string token)
            => _set.FirstOrDefaultAsync(d => d.Token == token);

        public async Task<IReadOnlyList<string>> GetTokensForCustomerAsync(Guid customerId)
            => await _set.Where(d => d.CustomerId == customerId)
                         .Select(d => d.Token)
                         .ToListAsync();

        public async Task RemoveByTokensAsync(IEnumerable<string> tokens)
        {
            var list = tokens.ToList();
            if (list.Count == 0) return;
            await _set.Where(d => list.Contains(d.Token)).ExecuteDeleteAsync();
        }
    }
}
