using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Services;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Tests.Application
{
    [TestClass]
    public class CustomerServiceTests
    {
        private sealed class FakeCustomers : ICustomerRepository
        {
            public List<Customer> Items { get; } = new();

            public Task<Customer?> GetByEmailAsync(string email)
                => Task.FromResult(Items.FirstOrDefault(c => c.User.Email == email));
            public Task<Customer?> GetByPhoneNumberAsync(string phoneNumber)
                => Task.FromResult(Items.FirstOrDefault(c => c.User.PhoneNumber == phoneNumber));
            public Task<Customer?> GetByIdAsync(Guid id)
                => Task.FromResult(Items.FirstOrDefault(c => c.CustomerId == id));
            public Task<Customer> AddAsync(Customer entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<Customer>> GetAllAsync() => Task.FromResult<IEnumerable<Customer>>(Items);
            public Task Update(Customer entity) => Task.CompletedTask;
            public Task Delete(Customer entity) { Items.Remove(entity); return Task.CompletedTask; }
        }

        private sealed class FakeUsers : IUserRepository
        {
            public Task<Role?> GetRoleAsync(Guid userId) => Task.FromResult<Role?>(null);
            public Task<UserProfile?> GetProfileAsync(Guid userId) => Task.FromResult<UserProfile?>(null);
            public Task<User?> GetByIdAsync(Guid userId) => Task.FromResult<User?>(null);
        }

        private sealed class FakeUnitOfWork : IUnitOfWork
        {
            public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) => Task.FromResult(1);
        }

        private static (CustomerService Service, FakeCustomers Customers) Create()
        {
            var customers = new FakeCustomers();
            return (new CustomerService(customers, new FakeUnitOfWork(), new FakeUsers()), customers);
        }

        private static CreateCustomerDto NewCustomer(string address = "Not provided yet")
            => new("Thandi", "Mokoena", "thandi@example.com", "", "0821234567", "Bloemfontein", address);

        [TestMethod]
        public async Task Register_ShouldSaveTheCustomerAsACustomerUser()
        {
            var (service, customers) = Create();
            var userId = Guid.NewGuid();

            await service.RegisterCustomerAsync(userId, NewCustomer());

            var saved = customers.Items.Single();
            Assert.AreEqual(userId, saved.UserId);
            Assert.AreEqual(Role.Customer, saved.User.Role);
        }

        [TestMethod]
        public async Task Register_TheSameAccountTwice_ShouldThrow()
        {
            var (service, _) = Create();
            var userId = Guid.NewGuid();
            await service.RegisterCustomerAsync(userId, NewCustomer());

            await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => service.RegisterCustomerAsync(userId, NewCustomer()));
        }

        [TestMethod]
        public async Task GetCustomer_ShouldPutEachValueInItsOwnField()
        {
            var (service, _) = Create();
            var userId = Guid.NewGuid();
            await service.RegisterCustomerAsync(userId, NewCustomer("12 Main Road, Botshabelo"));

            var dto = await service.GetCustomerByUserIdAsync(userId);

            Assert.IsNotNull(dto);
            Assert.AreEqual("Thandi", dto.FirstName);
            Assert.AreEqual("Mokoena", dto.LastName);
            Assert.AreEqual("12 Main Road, Botshabelo", dto.Address);
            Assert.AreEqual("Bloemfontein", dto.City);
            Assert.AreEqual("thandi@example.com", dto.Email);
            Assert.AreNotEqual(dto.Address, dto.ReferralCode);
            Assert.AreEqual(8, dto.ReferralCode.Length);
        }
    }
}
