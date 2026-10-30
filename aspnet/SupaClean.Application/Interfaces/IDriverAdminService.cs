using SupaClean.Application.DTOs;

namespace SupaClean.Application.Interfaces
{
    public interface IDriverAdminService
    {
        // Adds a driver: a sign-in account they can use at the Driver Log In page,
        // and their user, employee and driver records. Returns the temporary password.
        Task<AddDriverResult> AddDriverAsync(AddDriverDto dto);
    }
}
