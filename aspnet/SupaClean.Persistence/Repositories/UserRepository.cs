using Microsoft.EntityFrameworkCore;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Repositories
{
    public class UserRepository : IUserRepository
    {
        private readonly AppDbContext _db;
        public UserRepository(AppDbContext db) => _db = db;

        public async Task<SupaClean.Domain.Entities.User?> GetByIdAsync(Guid userId)
            => await _db.Users.FirstOrDefaultAsync(u => u.UserId == userId);

        public async Task<IReadOnlyList<SupaClean.Domain.Entities.User>> GetByRoleAsync(Role role)
            => await _db.Users.AsNoTracking().Where(u => u.Role == role).ToListAsync();

        public async Task<SupaClean.Domain.Entities.User?> GetByEmailAsync(string email)
        {
            var wanted = email.Trim().ToLowerInvariant();
            return await _db.Users.FirstOrDefaultAsync(u => u.Email == wanted);
        }

        public async Task AddAsync(SupaClean.Domain.Entities.User user)
            => await _db.Users.AddAsync(user);

        public void Remove(SupaClean.Domain.Entities.User user)
            => _db.Users.Remove(user);

        public async Task<Role?> GetRoleAsync(Guid userId)
            => await _db.Users.Where(u => u.UserId == userId)
                              .Select(u => (Role?)u.Role)
                              .FirstOrDefaultAsync();

        public async Task<UserProfile?> GetProfileAsync(Guid userId)
    => await _db.Users.Where(u => u.UserId == userId)
                      .Select(u => new UserProfile(u.UserId, u.FirstName + " " + u.LastName, u.Role))
                      .FirstOrDefaultAsync();
    }
}
