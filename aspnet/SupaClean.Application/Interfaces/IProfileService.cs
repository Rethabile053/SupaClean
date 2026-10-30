using SupaClean.Application.DTOs;

namespace SupaClean.Application.Interfaces
{
    public interface IProfileService
    {
        // The signed-in person's details, from the Users table.
        Task<ProfileDto> GetAsync(Guid userId);

        // Name and phone number. The email is the login and is not changed here.
        Task<ProfileDto> UpdateAsync(Guid userId, UpdateProfileDto dto);
    }
}
