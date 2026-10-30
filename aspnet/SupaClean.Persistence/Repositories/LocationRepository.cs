using Microsoft.EntityFrameworkCore;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Domain.Entities;

namespace SupaClean.Persistence.Repositories
{
    public class LocationRepository : ILocationRepository
    {
        private readonly AppDbContext _db;
        public LocationRepository(AppDbContext db) => _db = db;

        public async Task<Location?> FindAsync(string addressLine1, string city)
        {
            var line = addressLine1.Trim().ToLower();
            var town = city.Trim().ToLower();
            return await _db.Locations.FirstOrDefaultAsync(l =>
                l.AddressLine1.ToLower() == line && l.AddressCity.ToLower() == town);
        }

        public async Task AddAsync(Location location) => await _db.Locations.AddAsync(location);
    }
}
