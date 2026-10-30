using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Services;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Tests.Application
{
    [TestClass]
    public class ProfileServiceTests
    {
        private sealed class FakeUsers : IUserRepository
        {
            public List<User> Items { get; } = new();
            public Task<Role?> GetRoleAsync(Guid userId) => Task.FromResult<Role?>(Items.FirstOrDefault(u => u.UserId == userId)?.Role);
            public Task<UserProfile?> GetProfileAsync(Guid userId) => throw new NotImplementedException();
            public Task<User?> GetByIdAsync(Guid userId) => Task.FromResult(Items.FirstOrDefault(u => u.UserId == userId));
            public Task<IReadOnlyList<User>> GetByRoleAsync(Role role) => Task.FromResult<IReadOnlyList<User>>(Items.Where(u => u.Role == role).ToList());
            public Task<User?> GetByEmailAsync(string email) => Task.FromResult(Items.FirstOrDefault(u => u.Email == email.Trim().ToLowerInvariant()));
            public Task AddAsync(User user) { Items.Add(user); return Task.CompletedTask; }
            public void Remove(User user) => Items.Remove(user);
        }

        private sealed class FakeUnitOfWork : IUnitOfWork
        {
            public int Saves { get; private set; }
            public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) { Saves++; return Task.FromResult(1); }
        }

        private static (ProfileService Service, User User, FakeUnitOfWork Uow) Create(Role role = Role.Driver)
        {
            var users = new FakeUsers();
            var user = new User(Guid.NewGuid(), "Sipho", "Dlamini", "Sipho@Example.com", "0821234567", role);
            users.Items.Add(user);
            var uow = new FakeUnitOfWork();
            return (new ProfileService(users, uow), user, uow);
        }

        [TestMethod]
        public async Task Get_ShouldReturnTheDetailsGivenAtSignUp()
        {
            var (service, user, _) = Create();

            var profile = await service.GetAsync(user.UserId);

            Assert.AreEqual("Sipho Dlamini", profile.FullName);
            Assert.AreEqual("sipho@example.com", profile.Email);
            Assert.AreEqual("0821234567", profile.PhoneNumber);
            Assert.AreEqual("Driver", profile.RoleName);
        }

        [TestMethod]
        public async Task Get_ShouldNameTheAdminRole()
        {
            var (service, user, _) = Create(Role.Admin);
            Assert.AreEqual("Administrator", (await service.GetAsync(user.UserId)).RoleName);
        }

        [TestMethod]
        public async Task Get_ShouldAskTheUserToLogInAgain_WhenTheyAreNotInTheDatabase()
        {
            var (service, _, _) = Create();
            var ex = await Assert.ThrowsExactlyAsync<KeyNotFoundException>(() => service.GetAsync(Guid.NewGuid()));
            StringAssert.Contains(ex.Message, "log in again");
        }

        [TestMethod]
        public async Task Update_ShouldSaveNameAndPhone_ButNeverTheEmail()
        {
            var (service, user, uow) = Create();

            var profile = await service.UpdateAsync(user.UserId, new UpdateProfileDto(" Themba ", "Nkosi", " +27 82 000 1111 "));

            Assert.AreEqual("Themba Nkosi", profile.FullName);
            Assert.AreEqual("+27 82 000 1111", profile.PhoneNumber);
            Assert.AreEqual("sipho@example.com", profile.Email);
            Assert.AreEqual(1, uow.Saves);
        }

        [TestMethod]
        public async Task Update_ShouldClearThePhone_WhenLeftBlank()
        {
            var (service, user, _) = Create();
            var profile = await service.UpdateAsync(user.UserId, new UpdateProfileDto("Sipho", "Dlamini", "  "));
            Assert.IsNull(profile.PhoneNumber);
        }

        [TestMethod]
        public async Task Update_ShouldRefuseBlankNamesAndBadPhones_WithoutSaving()
        {
            var (service, user, uow) = Create();

            await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.UpdateAsync(user.UserId, new UpdateProfileDto("", "Dlamini", null)));
            await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.UpdateAsync(user.UserId, new UpdateProfileDto("Sipho", " ", null)));
            await Assert.ThrowsExactlyAsync<BusinessRuleException>(() => service.UpdateAsync(user.UserId, new UpdateProfileDto("Sipho", "Dlamini", "call me")));

            Assert.AreEqual(0, uow.Saves);
        }
    }
}
