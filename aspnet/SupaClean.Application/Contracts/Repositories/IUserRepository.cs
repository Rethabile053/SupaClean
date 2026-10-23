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
    }
}
