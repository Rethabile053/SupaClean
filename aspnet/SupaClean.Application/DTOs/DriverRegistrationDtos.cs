namespace SupaClean.Application.DTOs
{
    // What a driver fills in on the Create Account page.
    public record RegisterDriverDto(string FirstName, string LastName, string Email, string Password,
        string? PhoneNumber = null);

    // A driver who has signed up and is waiting for an admin to approve them.
    public record PendingDriverDto(Guid UserId, string FullName, string Email, string? PhoneNumber);

    // The outcome of creating a sign-in account with the identity provider (Supabase).
    public record SignUpResult(bool Success, string? Error, Guid? UserId)
    {
        public static SignUpResult Created(Guid userId) => new(true, null, userId);
        public static SignUpResult Failed(string error) => new(false, error, null);
    }
}
