using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Services
{
    public class CustomerService : ICustomerService 
    {
        private readonly ICustomerRepository _customerRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IUserRepository _userRepository;
        private readonly ILocationRepository _locations;

        public CustomerService(ICustomerRepository customerRepository, IUnitOfWork unitOfWork,
            IUserRepository userRepository, ILocationRepository locations)
        {
            _customerRepository = customerRepository;
            _unitOfWork = unitOfWork;
            _userRepository = userRepository;
            _locations = locations;
        }

        public async Task<CustomerDto?> GetCustomerByIdAsync(Guid customerId)
        {
            var customer = await _customerRepository.GetByIdAsync(customerId);
            if (customer == null) return null;

            return MapToDto(customer);
        }

        public async Task<CustomerDto?> GetCustomerByUserIdAsync(Guid userId)
        {
           
            var customers = await _customerRepository.GetAllAsync();
            var customer = customers.FirstOrDefault(c => c.UserId == userId);

            return customer == null ? null : MapToDto(customer);
        }

        public async Task<Guid> RegisterCustomerAsync(Guid userId, CreateCustomerDto dto)
        {
            var existing = await GetCustomerByUserIdAsync(userId);
            if (existing is not null)
                throw new BusinessRuleException("A customer profile already exists for this account.");

            // The user row may already exist (e.g. made at sign-up); reuse it
            // instead of inserting the same id twice.
            var user = await _userRepository.GetByIdAsync(userId)
                ?? new User(userId, dto.FirstName, dto.LastName, dto.Email, dto.PhoneNumber);

            var customer = new Customer(user, dto.City, dto.Address);   

            await _customerRepository.AddAsync(customer);
            await RememberLocationAsync(customer.Address, customer.City);
            await _unitOfWork.SaveChangesAsync();

            return customer.CustomerId;
        }

        public async Task UpdateCustomerProfileAsync(Guid userId, UpdateCustomerDto dto)
        {
            var customers = await _customerRepository.GetAllAsync();
            var customer = customers.FirstOrDefault(c => c.UserId == userId)
                ?? throw new KeyNotFoundException("Customer profile not found.");

            customer.UpdateDetails(dto.City, dto.Address);

            _customerRepository.Update(customer);
            await RememberLocationAsync(customer.Address, customer.City);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<IEnumerable<CustomerDto>> GetAllCustomersAsync()
        {
            var customers = await _customerRepository.GetAllAsync();
            return customers.Select(MapToDto);
        }

        public async Task<IEnumerable<CustomerDto>> SearchCustomersAsync(string? search)
        {
            var customers = await _customerRepository.GetAllAsync();

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim();
                bool Has(string? value) => value?.Contains(term, StringComparison.OrdinalIgnoreCase) == true;

                customers = customers.Where(c =>
                    Has(c.User?.FirstName) || Has(c.User?.LastName) ||
                    Has(c.User?.Email) || Has(c.User?.PhoneNumber) || Has(c.City));
            }

            return customers.OrderBy(c => c.User?.LastName)
                            .ThenBy(c => c.User?.FirstName)
                            .Select(MapToDto);
        }


        // Every address a customer saves is also kept in the Locations table, once. A
        // placeholder such as "Not provided yet" is not a place, so it is skipped.
        private async Task RememberLocationAsync(string address, string city)
        {
            if (string.IsNullOrWhiteSpace(address) || string.IsNullOrWhiteSpace(city)) return;
            if (address.Trim().Equals(NoAddressYet, StringComparison.OrdinalIgnoreCase)) return;
            if (await _locations.FindAsync(address, city) is not null) return;

            await _locations.AddAsync(new Location(address.Trim(), city.Trim()));
        }

        public const string NoAddressYet = "Not provided yet";

        private static CustomerDto MapToDto(Customer customer)
        {
            return new CustomerDto(
                customer.CustomerId,
                customer.UserId,
                customer.User?.FirstName ?? string.Empty,
                customer.User?.Email ?? string.Empty,
                customer.User?.PhoneNumber ?? string.Empty,
                customer.City,
                customer.User?.LastName ?? string.Empty,
                customer.ReferralCode,
                customer.Address
               );
        }
    
    }
}
