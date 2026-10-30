using SupaClean.Application.DTOs;

namespace SupaClean.Application.Contracts.Repositories
{
    // Creates the sign-in account for a driver who is registering themselves. This is
    // the ordinary public sign-up, so it needs no special key.
    public interface IDriverSignUp
    {
        // If the email already has a sign-in account and the password is right (for
        // example a driver who was declined and is trying again), that account's id is
        // returned instead of creating a second one.
        Task<SignUpResult> SignUpAsync(string email, string password, string fullName,
            string? phoneNumber, CancellationToken cancellationToken = default);
    }
}
