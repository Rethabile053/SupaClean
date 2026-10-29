using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Services;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Tests.Application
{
    [TestClass]
    public class DeviceServiceTests
    {
        private sealed class FakeDevices : IDeviceTokenRepository
        {
            public List<DeviceToken> Items { get; } = new();

            public Task<DeviceToken?> GetByTokenAsync(string token)
                => Task.FromResult(Items.FirstOrDefault(d => d.Token == token));

            public Task<IReadOnlyList<string>> GetTokensForCustomerAsync(Guid customerId)
                => Task.FromResult<IReadOnlyList<string>>(
                    Items.Where(d => d.CustomerId == customerId).Select(d => d.Token).ToList());

            public Task RemoveByTokensAsync(IEnumerable<string> tokens)
            {
                Items.RemoveAll(d => tokens.Contains(d.Token));
                return Task.CompletedTask;
            }

            public Task<DeviceToken?> GetByIdAsync(Guid id)
                => Task.FromResult(Items.FirstOrDefault(d => d.DeviceTokenId == id));
            public Task<DeviceToken> AddAsync(DeviceToken entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<DeviceToken>> GetAllAsync() => Task.FromResult<IEnumerable<DeviceToken>>(Items);
            public Task Update(DeviceToken entity) => Task.CompletedTask;
            public Task Delete(DeviceToken entity) { Items.Remove(entity); return Task.CompletedTask; }
        }

        private sealed class FakeUnitOfWork : IUnitOfWork
        {
            public int Saves { get; private set; }
            public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
            {
                Saves++;
                return Task.FromResult(1);
            }
        }

        private static (DeviceService Service, FakeDevices Devices, FakeUnitOfWork Unit) Create()
        {
            var devices = new FakeDevices();
            var unit = new FakeUnitOfWork();
            return (new DeviceService(devices, unit), devices, unit);
        }

        [TestMethod]
        public async Task Register_ANewPhone_ShouldBeSaved()
        {
            var (service, devices, unit) = Create();
            var customer = Guid.NewGuid();

            await service.RegisterAsync(customer, new RegisterDeviceDto("token-1", "android"));

            Assert.AreEqual(1, devices.Items.Count);
            Assert.AreEqual(customer, devices.Items[0].CustomerId);
            Assert.AreEqual(1, unit.Saves);
        }

        [TestMethod]
        public async Task Register_ThePhoneAgain_ShouldNotAddADuplicate()
        {
            var (service, devices, _) = Create();
            var customer = Guid.NewGuid();

            await service.RegisterAsync(customer, new RegisterDeviceDto("token-1", "android"));
            await service.RegisterAsync(customer, new RegisterDeviceDto("token-1", "android"));

            Assert.AreEqual(1, devices.Items.Count);
        }

        [TestMethod]
        public async Task Register_APhoneAnotherCustomerUsed_ShouldMoveToTheNewCustomer()
        {
            var (service, devices, _) = Create();
            var first = Guid.NewGuid();
            var second = Guid.NewGuid();

            await service.RegisterAsync(first, new RegisterDeviceDto("token-1", "android"));
            await service.RegisterAsync(second, new RegisterDeviceDto("token-1", "android"));

            Assert.AreEqual(1, devices.Items.Count);
            Assert.AreEqual(second, devices.Items[0].CustomerId);
        }

        [TestMethod]
        public async Task Register_ABlankToken_ShouldThrowAndSaveNothing()
        {
            var (service, devices, unit) = Create();

            await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => service.RegisterAsync(Guid.NewGuid(), new RegisterDeviceDto("  ", "android")));

            Assert.AreEqual(0, devices.Items.Count);
            Assert.AreEqual(0, unit.Saves);
        }
    }
}
