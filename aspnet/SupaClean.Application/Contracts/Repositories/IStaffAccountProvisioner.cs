using SupaClean.Application.DTOs;

namespace SupaClean.Application.Contracts.Repositories
{
    // Creates and removes the sign-in account (in Supabase Auth) of a staff member.
    // This is separate from the Users / Employees / Drivers rows in our own database.
    public interface IStaffAccountProvisioner
    {
        // Makes a confirmed account the person can sign in to straight away.
        Task<StaffAccountResult> CreateAsync(string email, string password, string fullName, string? phoneNumber,
            CancellationToken cancellationToken = default);

        // Removes an account again, for when the rest of the work could not be saved.
        Task DeleteAsync(Guid userId, CancellationToken cancellationToken = default);
    }
}
