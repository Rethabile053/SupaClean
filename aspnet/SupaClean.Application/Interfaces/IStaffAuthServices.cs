using SupaClean.Application.DTOs;
using SupaClean.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Interfaces
{
    public interface IStaffAuthService
    {
        Task<StaffLoginResult> SignInAsync(string email, string password, Role requiredRole);
    }
}
