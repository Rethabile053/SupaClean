using System.Reflection;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Services;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Tests.Application
{
    [TestClass]
    public class DriverAdminServiceTests
    {
        private sealed class FakeUsers : IUserRepository
        {
            public List<User> Items { get; } = new();
            public Task<Role?> GetRoleAsync(Guid userId) => Task.FromResult<Role?>(Items.FirstOrDefault(u => u.UserId == userId)?.Role);
            public Task<UserProfile?> GetProfileAsync(Guid userId) => throw new NotImplementedException();
            public Task<User?> GetByIdAsync(Guid userId) => Task.FromResult(Items.FirstOrDefault(u => u.UserId == userId));
            public Task<IReadOnlyList<User>> GetByRoleAsync(Role role)
                => Task.FromResult<IReadOnlyList<User>>(Items.Where(u => u.Role == role).ToList());
            public Task<User?> GetByEmailAsync(string email)
                => Task.FromResult(Items.FirstOrDefault(u => u.Email == email.Trim().ToLowerInvariant()));
            public Task AddAsync(User user) { Items.Add(user); return Task.CompletedTask; }
        }

        private sealed class FakeDrivers : IDriverRepository
        {
            public List<Driver> Items { get; } = new();
            public Task<Driver?> GetByUserIdAsync(Guid userId) => Task.FromResult(Items.FirstOrDefault(d => d.Employee?.UserId == userId));
            public Task<Driver> GetOrCreateForUserAsync(User user, string? licenseNumber = null)
            {
                var employee = new Employee(user.UserId, "Driver");
                var driver = new Driver(employee.EmployeeId, "", user.Email, licenseNumber ?? "Not recorded");
                typeof(Driver).GetProperty("Employee")!.SetValue(driver, employee);
                Items.Add(driver);
                return Task.FromResult(driver);
            }
            public Task<Driver?> GetByIdAsync(Guid id) => Task.FromResult(Items.FirstOrDefault(d => d.DriverId == id));
            public Task<Driver> AddAsync(Driver entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<Driver>> GetAllAsync() => Task.FromResult<IEnumerable<Driver>>(Items);
            public Task Update(Driver entity) => Task.CompletedTask;
            public Task Delete(Driver entity) => Task.CompletedTask;
        }

        private sealed class FakeAccounts : IStaffAccountProvisioner
        {
            public List<(string Email, string Password, string FullName, string? Phone)> Created { get; } = new();
            public List<Guid> Deleted { get; } = new();
            public string? FailWith { get; set; }
            public Guid LastId { get; private set; }

            public Task<StaffAccountResult> CreateAsync(string email, string password, string fullName, string? phone, CancellationToken ct = default)
            {
                if (FailWith is not null) return Task.FromResult(StaffAccountResult.Failed(FailWith));
                Created.Add((email, password, fullName, phone));
                LastId = Guid.NewGuid();
                return Task.FromResult(StaffAccountResult.Created(LastId));
            }

            public Task DeleteAsync(Guid userId, CancellationToken ct = default) { Deleted.Add(userId); return Task.CompletedTask; }
        }

        private sealed class FakeUnitOfWork : IUnitOfWork
        {
            public int Saves { get; private set; }
            public bool Fail { get; set; }
            public Task<int> SaveChangesAsync(CancellationToken ct = default)
            {
                if (Fail) throw new InvalidOperationException("database is down");
                Saves++;
                return Task.FromResult(1);
            }
        }

        private static (DriverAdminService Service, FakeUsers Users, FakeDrivers Drivers, FakeAccounts Accounts, FakeUnitOfWork Unit) Create()
        {
            var users = new FakeUsers();
            var drivers = new FakeDrivers();
            var accounts = new FakeAccounts();
            var unit = new FakeUnitOfWork();
            return (new DriverAdminService(users, drivers, accounts, unit), users, drivers, accounts, unit);
        }

        private static AddDriverDto Dto(string email = "sipho@example.com")
            => new(" Sipho ", " Dlamini ", email, " 0821234567 ", " LIC-99 ");

        [TestMethod]
        public async Task AddDriver_ShouldCreateTheLoginAndTheDriverRecords()
        {
            var (service, users, drivers, accounts, unit) = Create();

            var result = await service.AddDriverAsync(Dto());

            Assert.AreEqual("Sipho Dlamini", result.FullName);
            Assert.AreEqual("sipho@example.com", result.Email);
            Assert.AreEqual(accounts.LastId, result.UserId);

            var created = accounts.Created.Single();
            Assert.AreEqual("sipho@example.com", created.Email);
            Assert.AreEqual(result.TemporaryPassword, created.Password);
            Assert.AreEqual("0821234567", created.Phone);

            var user = users.Items.Single();
            Assert.AreEqual(Role.Driver, user.Role);
            Assert.AreEqual(result.UserId, user.UserId);
            Assert.AreEqual("Sipho", user.FirstName);
            Assert.AreEqual("Dlamini", user.LastName);

            Assert.AreEqual("LIC-99", drivers.Items.Single().LicenseNumber);
            Assert.AreEqual(1, unit.Saves);
        }

        [TestMethod]
        public async Task AddDriver_WithoutALicence_ShouldSayNotRecorded()
        {
            var (service, _, drivers, _, _) = Create();

            await service.AddDriverAsync(new AddDriverDto("Sipho", "Dlamini", "sipho@example.com"));

            Assert.AreEqual("Not recorded", drivers.Items.Single().LicenseNumber);
        }

        [TestMethod]
        public async Task AddDriver_TheTemporaryPassword_ShouldBeStrongAndDifferentEachTime()
        {
            var (service, _, _, _, _) = Create();

            var a = (await service.AddDriverAsync(Dto("a@example.com"))).TemporaryPassword;
            var b = (await service.AddDriverAsync(Dto("b@example.com"))).TemporaryPassword;

            foreach (var password in new[] { a, b })
            {
                Assert.AreEqual(12, password.Length);
                Assert.IsTrue(password.Any(char.IsUpper), "needs an upper case letter");
                Assert.IsTrue(password.Any(char.IsLower), "needs a lower case letter");
                Assert.IsTrue(password.Any(char.IsDigit), "needs a digit");
                Assert.IsFalse(password.Any(c => "0O1lI".Contains(c)), "no look-alike characters");
            }
            Assert.AreNotEqual(a, b);
        }

        [TestMethod]
        public async Task AddDriver_AnEmailThatIsAlreadyUsed_ShouldBeRefusedBeforeAnythingIsCreated()
        {
            var (service, users, _, accounts, unit) = Create();
            users.Items.Add(new User(Guid.NewGuid(), "Cara", "Customer", "sipho@example.com", "0711111111", Role.Customer));

            var error = await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.AddDriverAsync(Dto()));

            StringAssert.Contains(error.Message, "already has an account");
            Assert.AreEqual(0, accounts.Created.Count);
            Assert.AreEqual(0, unit.Saves);
        }

        [TestMethod]
        public async Task AddDriver_AnExistingDriverWithTheSameEmail_ShouldSaySo()
        {
            var (service, users, _, accounts, _) = Create();
            users.Items.Add(new User(Guid.NewGuid(), "Sipho", "Dlamini", "sipho@example.com", "", Role.Driver));

            var error = await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.AddDriverAsync(Dto("SIPHO@example.com")));

            StringAssert.Contains(error.Message, "already a driver");
            Assert.AreEqual(0, accounts.Created.Count);
        }

        [TestMethod]
        public async Task AddDriver_MissingOrBadDetails_ShouldBeRefused()
        {
            var (service, _, _, accounts, _) = Create();

            await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => service.AddDriverAsync(new AddDriverDto("", "Dlamini", "a@b.co")));
            await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => service.AddDriverAsync(new AddDriverDto("Sipho", "  ", "a@b.co")));
            await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => service.AddDriverAsync(new AddDriverDto("Sipho", "Dlamini", "not-an-email")));
            await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => service.AddDriverAsync(new AddDriverDto("Sipho", "Dlamini", "")));

            Assert.AreEqual(0, accounts.Created.Count);
        }

        [TestMethod]
        public async Task AddDriver_WhenTheLoginCannotBeCreated_ShouldSaveNothingAndSayWhy()
        {
            var (service, users, drivers, accounts, unit) = Create();
            accounts.FailWith = "A login account with that email already exists.";

            var error = await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.AddDriverAsync(Dto()));

            Assert.AreEqual("A login account with that email already exists.", error.Message);
            Assert.AreEqual(0, users.Items.Count);
            Assert.AreEqual(0, drivers.Items.Count);
            Assert.AreEqual(0, unit.Saves);
        }

        [TestMethod]
        public async Task AddDriver_WhenTheDatabaseFails_ShouldRemoveTheLoginAgain()
        {
            var (service, _, _, accounts, unit) = Create();
            unit.Fail = true;

            var error = await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.AddDriverAsync(Dto()));

            StringAssert.Contains(error.Message, "no account was kept");
            CollectionAssert.AreEqual(new[] { accounts.LastId }, accounts.Deleted);
        }
    }
}
