namespace SupaClean.Application.DTOs
{
    // A person who can be given deliveries: a user with the Driver role.
    public record DriverOptionDto(Guid UserId, string FullName, string? Email);
}
