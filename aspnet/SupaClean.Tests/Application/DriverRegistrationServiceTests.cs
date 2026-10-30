using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Services;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Tests.Application
{
    [TestClass]
    public class DriverRegistrationServiceTests
    {
        private sealed class FakeUsers : IUserRepository
        {
            public List<User> Items { get; } = new();
            public Task<Role?> GetRoleAsync(Guid userId) => Task.FromResult<Role?>(Items.FirstOrDefault(u => u.UserId == userId)?.Role);
            public Task<UserProfile?> GetProfileAsync(Guid userId) => throw new NotImplementedException();
            public Task<User?> GetByIdAsync(Guid userId) => Task.FromResult(Items.FirstOrDefault(u => u.UserId == userId));
            public Task<IReadOnlyList<User>> GetByRoleAsync(Role role)
                => Task.FromResult<IReadOnlyList<User>>(Items.Where(u => u.Role == role).ToList());
            public Task<User?> GetByEmailAsync(string email) => Task.FromResult(Items.FirstOrDefault(u => u.Email == email.Trim().ToLowerInvariant()));
            public Task AddAsync(User user) { Items.Add(user); return Task.CompletedTask; }
            public void Remove(User user) => Items.Remove(user);
        }

        private sealed class FakeDrivers : IDriverRepository
        {
            public List<User> MadeFor { get; } = new();
            public Task<Driver?> GetByUserIdAsync(Guid userId) => Task.FromResult<Driver?>(null);
            public Task<Driver> GetOrCreateForUserAsync(User user)
            {
                MadeFor.Add(user);
                return Task.FromResult(new Driver(Guid.NewGuid(), "", user.Email, "Not recorded"));
            }
            public Task<Driver?> GetByIdAsync(Guid id) => Task.FromResult<Driver?>(null);
            public Task<Driver> AddAsync(Driver entity) => Task.FromResult(entity);
            public Task<IEnumerable<Driver>> GetAllAsync() => Task.FromResult<IEnumerable<Driver>>(new List<Driver>());
            public Task Update(Driver entity) => Task.CompletedTask;
            public Task Delete(Driver entity) => Task.CompletedTask;
        }

        private sealed class FakeSignUp : IDriverSignUp
        {
            public int Calls { get; private set; }
            public SignUpResult Result { get; set; } = SignUpResult.Created(Guid.NewGuid());
            public Task<SignUpResult> SignUpAsync(string email, string password, string fullName, string? phoneNumber, CancellationToken cancellationToken = default)
            { Calls++; return Task.FromResult(Result); }
        }

        private sealed class FakeUnitOfWork : IUnitOfWork
        {
            public int Saves { get; private set; }
            public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) { Saves++; return Task.FromResult(1); }
        }

        private static (DriverRegistrationService Service, FakeUsers Users, FakeDrivers Drivers, FakeSignUp SignUp, FakeUnitOfWork Uow) Create()
        {
            var users = new FakeUsers(); var drivers = new FakeDrivers(); var signUp = new FakeSignUp(); var uow = new FakeUnitOfWork();
            return (new DriverRegistrationService(users, drivers, signUp, uow), users, drivers, signUp, uow);
        }

        private static RegisterDriverDto Valid(string email = "Sipho@Example.com")
            => new("Sipho", "Dlamini", email, "longenough1", "0821234567");

        [TestMethod]
        public async Task Register_ShouldSaveThePersonAsPendingNotAsADriver()
        {
            var (service, users, drivers, signUp, uow) = Create();
            var id = Guid.NewGuid();
            signUp.Result = SignUpResult.Created(id);

            await service.RegisterAsync(Valid());

            var user = users.Items.Single();
            Assert.AreEqual(id, user.UserId);
            Assert.AreEqual(Role.PendingDriver, user.Role);
            Assert.AreEqual("sipho@example.com", user.Email);
            Assert.AreEqual(0, drivers.MadeFor.Count, "no driver record until an admin approves");
            Assert.AreEqual(1, uow.Saves);
        }

        [TestMethod]
        public async Task Register_ShouldRefuseBadDetails_BeforeCreatingAnAccount()
        {
            var (service, users, _, signUp, _) = Create();

            foreach (var bad in new[]
            {
                new RegisterDriverDto("", "Dlamini", "a@b.com", "longenough1"),
                new RegisterDriverDto("Sipho", " ", "a@b.com", "longenough1"),
                new RegisterDriverDto("Sipho", "Dlamini", "not-an-email", "longenough1"),
                new RegisterDriverDto("Sipho", "Dlamini", "a@b.com", "short"),
            })
            {
                await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.RegisterAsync(bad));
            }

            Assert.AreEqual(0, signUp.Calls);
            Assert.AreEqual(0, users.Items.Count);
        }

        [TestMethod]
        public async Task Register_ShouldRefuseAnEmailThatAlreadyHasAnAccount()
        {
            var (service, users, _, signUp, _) = Create();
            users.Items.Add(new User(Guid.NewGuid(), "Cus", "Tomer", "sipho@example.com", "0", Role.Customer));

            var ex = await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.RegisterAsync(Valid()));

            StringAssert.Contains(ex.Message, "already has an account");
            Assert.AreEqual(0, signUp.Calls);
        }

        [TestMethod]
        public async Task Register_ShouldTellAPendingDriverTheyAreAlreadyWaiting()
        {
            var (service, users, _, _, _) = Create();
            users.Items.Add(new User(Guid.NewGuid(), "Sipho", "Dlamini", "sipho@example.com", "0", Role.PendingDriver));

            var ex = await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.RegisterAsync(Valid()));

            StringAssert.Contains(ex.Message, "waiting for approval");
        }

        [TestMethod]
        public async Task Register_ShouldNotSaveAnything_WhenTheSignUpFails()
        {
            var (service, users, _, signUp, uow) = Create();
            signUp.Result = SignUpResult.Failed("Could not reach Supabase to create the account. Please try again.");

            var ex = await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.RegisterAsync(Valid()));

            StringAssert.Contains(ex.Message, "Supabase");
            Assert.AreEqual(0, users.Items.Count);
            Assert.AreEqual(0, uow.Saves);
        }

        [TestMethod]
        public async Task GetPending_ShouldListOnlyPendingDrivers()
        {
            var (service, users, _, _, _) = Create();
            users.Items.Add(new User(Guid.NewGuid(), "Zed", "Pending", "z@x.com", "0", Role.PendingDriver));
            users.Items.Add(new User(Guid.NewGuid(), "Ann", "Pending", "a@x.com", "0", Role.PendingDriver));
            users.Items.Add(new User(Guid.NewGuid(), "Working", "Driver", "w@x.com", "0", Role.Driver));
            users.Items.Add(new User(Guid.NewGuid(), "Some", "Customer", "c@x.com", "0", Role.Customer));

            var pending = await service.GetPendingAsync();

            CollectionAssert.AreEqual(new[] { "Ann Pending", "Zed Pending" }, pending.Select(p => p.FullName).ToArray());
        }

        [TestMethod]
        public async Task Approve_ShouldMakeThemADriverWithDriverRecords()
        {
            var (service, users, drivers, _, uow) = Create();
            var user = new User(Guid.NewGuid(), "Sipho", "Dlamini", "s@x.com", "0", Role.PendingDriver);
            users.Items.Add(user);

            await service.ApproveAsync(user.UserId);

            Assert.AreEqual(Role.Driver, user.Role);
            Assert.AreEqual(1, drivers.MadeFor.Count);
            Assert.AreEqual(1, uow.Saves);
        }

        [TestMethod]
        public async Task Approve_ShouldRefuseSomeoneWhoIsNotPending()
        {
            var (service, users, drivers, _, _) = Create();
            var customer = new User(Guid.NewGuid(), "Cus", "Tomer", "c@x.com", "0", Role.Customer);
            users.Items.Add(customer);

            await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.ApproveAsync(customer.UserId));

            Assert.AreEqual(Role.Customer, customer.Role, "a customer must never be promoted");
            Assert.AreEqual(0, drivers.MadeFor.Count);
        }

        [TestMethod]
        public async Task Approve_ShouldSayWhenTheRequestIsGone()
        {
            var (service, _, _, _, _) = Create();
            await Assert.ThrowsExactlyAsync<KeyNotFoundException>(() => service.ApproveAsync(Guid.NewGuid()));
        }

        [TestMethod]
        public async Task Decline_ShouldRemoveThePendingRequest()
        {
            var (service, users, _, _, uow) = Create();
            var user = new User(Guid.NewGuid(), "Sipho", "Dlamini", "s@x.com", "0", Role.PendingDriver);
            users.Items.Add(user);

            await service.DeclineAsync(user.UserId);

            Assert.AreEqual(0, users.Items.Count);
            Assert.AreEqual(1, uow.Saves);
        }

        [TestMethod]
        public async Task Decline_ShouldNeverRemoveAWorkingDriverOrACustomer()
        {
            var (service, users, _, _, uow) = Create();
            var driver = new User(Guid.NewGuid(), "Work", "Ing", "w@x.com", "0", Role.Driver);
            var customer = new User(Guid.NewGuid(), "Cus", "Tomer", "c@x.com", "0", Role.Customer);
            users.Items.AddRange(new[] { driver, customer });

            await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.DeclineAsync(driver.UserId));
            await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.DeclineAsync(customer.UserId));

            Assert.AreEqual(2, users.Items.Count);
            Assert.AreEqual(0, uow.Saves);
        }
    }
}
