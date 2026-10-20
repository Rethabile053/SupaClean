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

        public CustomerService(ICustomerRepository customerRepository, IUnitOfWork unitOfWork)
        {
            _customerRepository = customerRepository;
            _unitOfWork = unitOfWork;
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

            var user = new User(userId, dto.FirstName, dto.LastName, dto.Email, dto.PhoneNumber);

            var customer = new Customer(user, dto.City, dto.Address);   // see step 3

            await _customerRepository.AddAsync(customer);
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
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<IEnumerable<CustomerDto>> GetAllCustomersAsync()
        {
            var customers = await _customerRepository.GetAllAsync();
            return customers.Select(MapToDto);
        }

       

        private static CustomerDto MapToDto(Customer customer)
        {
            return new CustomerDto(
                customer.CustomerId,
                customer.UserId,
                customer.User?.FirstName ?? string.Empty,
                customer.User?.Email ?? string.Empty,
                customer.User?.PhoneNumber ?? string.Empty,
                customer.City,
                customer.Address
            );
        }
    }
}
