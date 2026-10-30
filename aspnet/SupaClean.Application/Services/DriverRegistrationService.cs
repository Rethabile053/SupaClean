using System.Net.Mail;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Application.Services
{
    // Drivers create their own account and an admin approves it. Until then the user
    // has the PendingDriver role, which the driver portal and the Assign Driver page
    // both ignore.
    public class DriverRegistrationService : IDriverRegistrationService
    {
        public const int MinPasswordLength = 8;

        private readonly IUserRepository _users;
        private readonly IDriverRepository _drivers;
        private readonly IDriverSignUp _signUp;
        private readonly IUnitOfWork _unitOfWork;

        public DriverRegistrationService(IUserRepository users, IDriverRepository drivers,
            IDriverSignUp signUp, IUnitOfWork unitOfWork)
        {
            _users = users;
            _drivers = drivers;
            _signUp = signUp;
            _unitOfWork = unitOfWork;
        }

        public async Task RegisterAsync(RegisterDriverDto dto)
        {
            var first = (dto.FirstName ?? string.Empty).Trim();
            var last = (dto.LastName ?? string.Empty).Trim();
            var email = (dto.Email ?? string.Empty).Trim().ToLowerInvariant();
            var password = dto.Password ?? string.Empty;

            if (first.Length == 0) throw new BusinessRuleException("Enter your first name.");
            if (last.Length == 0) throw new BusinessRuleException("Enter your last name.");
            if (!IsEmail(email)) throw new BusinessRuleException("Enter a valid email address.");
            if (password.Length < MinPasswordLength)
                throw new BusinessRuleException($"Your password must be at least {MinPasswordLength} characters.");

            var existing = await _users.GetByEmailAsync(email);
            if (existing is not null)
                throw new BusinessRuleException(existing.Role == Role.PendingDriver
                    ? "This email has already asked to be a driver and is waiting for approval."
                    : "This email already has an account. Log in instead.");

            var phone = string.IsNullOrWhiteSpace(dto.PhoneNumber) ? null : dto.PhoneNumber.Trim();
            var account = await _signUp.SignUpAsync(email, password, $"{first} {last}", phone);
            if (!account.Success || account.UserId is null)
                throw new BusinessRuleException(account.Error ?? "Could not create the account. Please try again.");

            await _users.AddAsync(new User(account.UserId.Value, first, last, email, phone!, Role.PendingDriver));
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<IReadOnlyList<PendingDriverDto>> GetPendingAsync()
        {
            var pending = await _users.GetByRoleAsync(Role.PendingDriver);
            return pending
                .Select(u => new PendingDriverDto(u.UserId, $"{u.FirstName} {u.LastName}".Trim(), u.Email, u.PhoneNumber))
                .OrderBy(p => p.FullName, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        public async Task ApproveAsync(Guid userId)
        {
            var user = await _users.GetByIdAsync(userId)
                ?? throw new KeyNotFoundException("That driver request was not found. It may already have been handled.");

            user.ApproveDriver();
            // The Employee and Driver rows are made now, in the same save, so the new
            // driver is complete the moment they are approved.
            await _drivers.GetOrCreateForUserAsync(user);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task DeclineAsync(Guid userId)
        {
            var user = await _users.GetByIdAsync(userId)
                ?? throw new KeyNotFoundException("That driver request was not found. It may already have been handled.");

            // Only a pending request can be declined, never a working driver or a customer.
            if (user.Role != Role.PendingDriver)
                throw new BusinessRuleException("Only a driver who is waiting for approval can be declined.");

            _users.Remove(user);
            await _unitOfWork.SaveChangesAsync();
        }

        private static bool IsEmail(string email)
        {
            if (email.Length == 0 || email.Length > 120) return false;
            try { return new MailAddress(email).Address == email; }
            catch (FormatException) { return false; }
        }
    }
}
