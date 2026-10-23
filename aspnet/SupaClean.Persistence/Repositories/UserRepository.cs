using SupaClean.Application.Contracts.Repositories;
using Microsoft.EntityFrameworkCore;
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

        public async Task<Role?> GetRoleAsync(Guid userId)
            => await _db.Users.Where(u => u.UserId == userId)
                              .Select(u => (Role?)u.Role)
                              .FirstOrDefaultAsync();
    }
}
