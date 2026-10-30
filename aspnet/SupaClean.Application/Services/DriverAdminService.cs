using System.Security.Cryptography;
using System.Text.RegularExpressions;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Application.Services
{
    public class DriverAdminService : IDriverAdminService
    {
        private static readonly Regex EmailPattern = new(@"^[^@\s]+@[^@\s]+\.[^@\s]+$", RegexOptions.Compiled);

        private readonly IUserRepository _users;
        private readonly IDriverRepository _drivers;
        private readonly IStaffAccountProvisioner _accounts;
        private readonly IUnitOfWork _unitOfWork;

        public DriverAdminService(IUserRepository users, IDriverRepository drivers,
            IStaffAccountProvisioner accounts, IUnitOfWork unitOfWork)
        {
            _users = users;
            _drivers = drivers;
            _accounts = accounts;
            _unitOfWork = unitOfWork;
        }

        public async Task<AddDriverResult> AddDriverAsync(AddDriverDto dto)
        {
            var first = dto.FirstName?.Trim() ?? string.Empty;
            var last = dto.LastName?.Trim() ?? string.Empty;
            var email = dto.Email?.Trim().ToLowerInvariant() ?? string.Empty;
            var phone = string.IsNullOrWhiteSpace(dto.PhoneNumber) ? null : dto.PhoneNumber.Trim();
            var license = string.IsNullOrWhiteSpace(dto.LicenseNumber) ? null : dto.LicenseNumber.Trim();

            if (first.Length == 0) throw new BusinessRuleException("The driver's first name is required.");
            if (last.Length == 0) throw new BusinessRuleException("The driver's last name is required.");
            if (!EmailPattern.IsMatch(email)) throw new BusinessRuleException("Please enter a valid email address.");

            // One email, one person. Checked before anything is created.
            if (await _users.GetByEmailAsync(email) is { } existing)
                throw new BusinessRuleException(
                    existing.Role == Role.Driver
                        ? $"{email} is already a driver."
                        : $"{email} already has an account ({existing.Role}). Use a different email for the driver.");

            var password = NewTemporaryPassword();
            var account = await _accounts.CreateAsync(email, password, $"{first} {last}", phone);
            if (account.UserId is not { } userId)
                throw new BusinessRuleException(account.Error ?? "The login account could not be created.");

            try
            {
                var user = new User(userId, first, last, email, phone ?? string.Empty, Role.Driver);
                await _users.AddAsync(user);
                await _drivers.GetOrCreateForUserAsync(user, license);
                await _unitOfWork.SaveChangesAsync();
            }
            catch (Exception)
            {
                // Do not leave a login account behind that has no driver behind it.
                try { await _accounts.DeleteAsync(userId); } catch (Exception) { /* best effort */ }
                throw new BusinessRuleException(
                    "The driver could not be saved, so no account was kept. Please try again.");
            }

            return new AddDriverResult(userId, $"{first} {last}", email, password);
        }

        // 12 characters, easy to read out (no 0/O or 1/l/I), with an upper case letter,
        // a lower case letter and a digit.
        private static string NewTemporaryPassword()
        {
            const string upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
            const string lower = "abcdefghijkmnopqrstuvwxyz";
            const string digits = "23456789";
            var all = upper + lower + digits;

            var chars = new List<char>
            {
                upper[RandomNumberGenerator.GetInt32(upper.Length)],
                lower[RandomNumberGenerator.GetInt32(lower.Length)],
                digits[RandomNumberGenerator.GetInt32(digits.Length)],
            };
            while (chars.Count < 12)
                chars.Add(all[RandomNumberGenerator.GetInt32(all.Length)]);

            // Shuffle so the first three are not always upper, lower, digit.
            for (var i = chars.Count - 1; i > 0; i--)
            {
                var j = RandomNumberGenerator.GetInt32(i + 1);
                (chars[i], chars[j]) = (chars[j], chars[i]);
            }
            return new string(chars.ToArray());
        }
    }
}
