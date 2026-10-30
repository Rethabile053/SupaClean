namespace SupaClean.Application.DTOs
{
    // What the Profile page shows for whoever is signed in. The email is their login,
    // so it can be seen but not changed here.
    public record ProfileDto(Guid UserId, string FirstName, string LastName, string Email,
        string? PhoneNumber, string RoleName)
    {
        public string FullName => $"{FirstName} {LastName}".Trim();
    }

    public record UpdateProfileDto(string FirstName, string LastName, string? PhoneNumber);
}
