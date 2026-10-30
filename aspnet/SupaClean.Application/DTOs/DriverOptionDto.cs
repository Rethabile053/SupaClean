namespace SupaClean.Application.DTOs
{
    // A person who can be given deliveries: a user with the Driver role, and how
    // many jobs they have been given and not yet done.
    public record DriverOptionDto(Guid UserId, string FullName, string? Email, int OpenJobs = 0);
}
