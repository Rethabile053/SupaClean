using SupaClean.Application.DTOs;
using SupaClean.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Contracts.Repositories
{
  

    public interface IUserRepository
    {
        Task<Role?> GetRoleAsync(Guid userId);
        Task<UserProfile?> GetProfileAsync(Guid userId);
        Task<SupaClean.Domain.Entities.User?> GetByIdAsync(Guid userId);
        Task<IReadOnlyList<SupaClean.Domain.Entities.User>> GetByRoleAsync(Role role);
        Task<SupaClean.Domain.Entities.User?> GetByEmailAsync(string email);
        // Added to the context and saved with the next SaveChanges.
        Task AddAsync(SupaClean.Domain.Entities.User user);
        void Remove(SupaClean.Domain.Entities.User user);
    }
}
