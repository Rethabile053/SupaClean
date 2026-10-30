namespace SupaClean.Application.DTOs
{
    // What an admin types to add a driver.
    public record AddDriverDto(
        string FirstName,
        string LastName,
        string Email,
        string? PhoneNumber = null,
        string? LicenseNumber = null);

    // The new driver, and the temporary password to give them. It is shown to the
    // admin once and is not stored anywhere we can read it back.
    public record AddDriverResult(Guid UserId, string FullName, string Email, string TemporaryPassword);
}
