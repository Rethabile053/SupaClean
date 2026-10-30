namespace SupaClean.Application.DTOs
{
    // The outcome of creating a sign-in account: its id, or why it could not be made.
    public record StaffAccountResult(Guid? UserId, string? Error)
    {
        public static StaffAccountResult Created(Guid userId) => new(userId, null);
        public static StaffAccountResult Failed(string error) => new(null, error);
    }
}
