using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Application.Services
{
    public class ProfileService : IProfileService
    {
        private readonly IUserRepository _users;
        private readonly IUnitOfWork _unitOfWork;

        public ProfileService(IUserRepository users, IUnitOfWork unitOfWork)
        {
            _users = users;
            _unitOfWork = unitOfWork;
        }

        public async Task<ProfileDto> GetAsync(Guid userId)
        {
            var user = await _users.GetByIdAsync(userId)
                ?? throw new KeyNotFoundException("Your profile was not found. Please log in again.");
            return ToDto(user);
        }

        public async Task<ProfileDto> UpdateAsync(Guid userId, UpdateProfileDto dto)
        {
            var user = await _users.GetByIdAsync(userId)
                ?? throw new KeyNotFoundException("Your profile was not found. Please log in again.");

            var phone = string.IsNullOrWhiteSpace(dto.PhoneNumber) ? null : dto.PhoneNumber.Trim();
            if (phone is not null && (phone.Length > 30 || phone.Any(c => !(char.IsDigit(c) || " +-()".Contains(c)))))
                throw new BusinessRuleException("Enter a valid phone number, for example 082 123 4567.");

            user.UpdateContactInfo(dto.FirstName ?? string.Empty, dto.LastName ?? string.Empty, phone);
            await _unitOfWork.SaveChangesAsync();
            return ToDto(user);
        }

        private static ProfileDto ToDto(User user) => new(
            user.UserId, user.FirstName, user.LastName, user.Email, user.PhoneNumber, RoleName(user.Role));

        private static string RoleName(Role role) => role switch
        {
            Role.Admin => "Administrator",
            Role.Driver => "Driver",
            Role.PendingDriver => "Driver (waiting for approval)",
            _ => "Customer",
        };
    }
}
