using SupaClean.Application.Contracts;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Services;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Tests.Application
{
    [TestClass]
    public class ServiceCatalogTests
    {
        private sealed class FakeServices : IServiceRepository
        {
            public List<Service> Items { get; } = new();
            public HashSet<Guid> UsedByOrders { get; } = new();

            public Task<IEnumerable<Service>> GetActiveServicesAsync()
                => Task.FromResult<IEnumerable<Service>>(Items.Where(s => s.IsActive).ToList());
            public Task<bool> IsUsedByOrdersAsync(Guid serviceId)
                => Task.FromResult(UsedByOrders.Contains(serviceId));

            public Task<Service?> GetByIdAsync(Guid id)
                => Task.FromResult(Items.FirstOrDefault(s => s.ServiceId == id));
            public Task<Service> AddAsync(Service entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<Service>> GetAllAsync() => Task.FromResult<IEnumerable<Service>>(Items);
            public Task Update(Service entity) => Task.CompletedTask;
            public Task Delete(Service entity) { Items.Remove(entity); return Task.CompletedTask; }
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

        private static (ServiceCatalog Catalog, FakeServices Repo, FakeUnitOfWork Unit) Create()
        {
            var repo = new FakeServices();
            var unit = new FakeUnitOfWork();
            return (new ServiceCatalog(repo, unit), repo, unit);
        }

        [TestMethod]
        public async Task Create_ShouldSaveTheDescriptionAndStartActive()
        {
            var (catalog, repo, unit) = Create();

            var id = await catalog.CreateServiceAsync(
                new CreateServiceDto("Duvet clean", "  Large duvets  ", 3, 120m));

            var saved = repo.Items.Single();
            Assert.AreEqual(id, saved.ServiceId);
            Assert.AreEqual("Large duvets", saved.ServiceDescription);
            Assert.AreEqual(120m, saved.Price);
            Assert.AreEqual(3, saved.TurnaroundDays);
            Assert.IsTrue(saved.IsActive);
            Assert.AreEqual(1, unit.Saves);
        }

        [TestMethod]
        public async Task Create_WithABlankDescription_ShouldStoreNone()
        {
            var (catalog, repo, _) = Create();

            await catalog.CreateServiceAsync(new CreateServiceDto("Socks", "   ", 2, 10m));

            Assert.IsNull(repo.Items.Single().ServiceDescription);
        }

        [TestMethod]
        public async Task Create_WithoutAName_ShouldBeRefusedAndSaveNothing()
        {
            var (catalog, repo, unit) = Create();

            await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => catalog.CreateServiceAsync(new CreateServiceDto("  ", "x", 2, 10m)));

            Assert.AreEqual(0, repo.Items.Count);
            Assert.AreEqual(0, unit.Saves);
        }

        [TestMethod]
        public async Task Delete_AServiceNoOrderUses_ShouldRemoveIt()
        {
            var (catalog, repo, unit) = Create();
            var service = new Service("Napkins", 3.5m, 2);
            repo.Items.Add(service);

            await catalog.DeleteServiceAsync(service.ServiceId);

            Assert.AreEqual(0, repo.Items.Count);
            Assert.AreEqual(1, unit.Saves);
        }

        [TestMethod]
        public async Task Delete_AServiceOrdersUse_ShouldBeRefusedAndKept()
        {
            var (catalog, repo, unit) = Create();
            var service = new Service("Shirts", 28.9m, 2);
            repo.Items.Add(service);
            repo.UsedByOrders.Add(service.ServiceId);

            var error = await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => catalog.DeleteServiceAsync(service.ServiceId));

            StringAssert.Contains(error.Message, "Make it inactive instead");
            Assert.AreEqual(1, repo.Items.Count);
            Assert.AreEqual(0, unit.Saves);
        }

        [TestMethod]
        public async Task Delete_AServiceThatDoesNotExist_ShouldBeNotFound()
        {
            var (catalog, _, _) = Create();

            await Assert.ThrowsExactlyAsync<KeyNotFoundException>(
                () => catalog.DeleteServiceAsync(Guid.NewGuid()));
        }

        [TestMethod]
        public async Task SetActive_ShouldSwitchAServiceOffAndOn()
        {
            var (catalog, repo, _) = Create();
            var service = new Service("Boots", 90m, 3);
            repo.Items.Add(service);

            await catalog.SetServiceActiveAsync(service.ServiceId, false);
            Assert.IsFalse((await catalog.GetActiveServicesAsync()).Any());
            Assert.IsFalse((await catalog.GetAllServicesAsync()).Single().IsActive);

            await catalog.SetServiceActiveAsync(service.ServiceId, true);
            Assert.AreEqual(1, (await catalog.GetActiveServicesAsync()).Count());
        }

        // ---- categories ------------------------------------------------------

        [TestMethod]
        public async Task Create_ShouldSaveTheCategoryAndReturnItToTheApp()
        {
            var (catalog, repo, _) = Create();

            await catalog.CreateServiceAsync(
                new CreateServiceDto("Duvet clean", "", 3, 120m, "  Bedding & Linen "));

            Assert.AreEqual("Bedding & Linen", repo.Items.Single().Category);
            Assert.AreEqual("Bedding & Linen",
                (await catalog.GetActiveServicesAsync()).Single().Category);
        }

        [TestMethod]
        public async Task Create_WithoutACategory_ShouldLeaveItUnset()
        {
            var (catalog, repo, _) = Create();

            await catalog.CreateServiceAsync(new CreateServiceDto("Socks", "", 2, 10m));
            await catalog.CreateServiceAsync(new CreateServiceDto("Shorts", "", 2, 10m, "   "));

            Assert.IsTrue(repo.Items.All(s => s.Category is null));
        }

        [TestMethod]
        public async Task SetCategory_ShouldChangeAndClearIt()
        {
            var (catalog, repo, unit) = Create();
            var service = new Service("Boots", 90m, 3);
            repo.Items.Add(service);

            await catalog.SetServiceCategoryAsync(service.ServiceId, "Shoe Cleaning");
            Assert.AreEqual("Shoe Cleaning", service.Category);

            await catalog.SetServiceCategoryAsync(service.ServiceId, "  ");
            Assert.IsNull(service.Category);
            Assert.AreEqual(2, unit.Saves);
        }

        [TestMethod]
        public async Task SetCategory_ForAServiceThatDoesNotExist_ShouldBeNotFound()
        {
            var (catalog, _, _) = Create();

            await Assert.ThrowsExactlyAsync<KeyNotFoundException>(
                () => catalog.SetServiceCategoryAsync(Guid.NewGuid(), "Ironing"));
        }

        [TestMethod]
        public void Category_TooLong_ShouldBeRefused()
        {
            var tooLong = new string('x', Service.MaxCategoryLength + 1);

            Assert.ThrowsExactly<BusinessRuleException>(
                () => new Service("Socks", 10m, 2, null, tooLong));
        }

        // ---- the order guard -------------------------------------------------

        private sealed class FakeOrders : IOrderRepository
        {
            public List<Order> Added { get; } = new();
            public Task<Order> AddAsync(Order entity) { Added.Add(entity); return Task.FromResult(entity); }
            public Task<Order?> GetByIdAsync(Guid id) => throw new NotImplementedException();
            public Task<IEnumerable<Order>> GetAllAsync() => throw new NotImplementedException();
            public Task Update(Order entity) => throw new NotImplementedException();
            public Task Delete(Order entity) => throw new NotImplementedException();
            public Task<IEnumerable<Order>> GetByCustomerIdAsync(Guid customerId) => throw new NotImplementedException();
            public Task<Order?> GetWithItemsByIdAsync(Guid orderId) => throw new NotImplementedException();
            public Task<IEnumerable<Order>> GetDeliveryStopsAsync() => throw new NotImplementedException();
            public Task<IEnumerable<Order>> GetPendingOrdersAsync() => throw new NotImplementedException();
            public Task<Order?> GetByOrderSequenceAsync(int sequence) => throw new NotImplementedException();
        }

        private static OrderService CreateOrderService(FakeServices services, FakeOrders orders)
            => new(orders, services, null!, null!, null!, new FakeUnitOfWork(), null!);

        private static CreateOrderDTO DropOffOrderFor(Guid serviceId)
            => new(Guid.NewGuid(), null, null,
                new List<CreateOrderItemDto> { new(serviceId, 1, 28.9m, "Shirts") },
                "DropOff");

        [TestMethod]
        public async Task PlaceOrder_ForAServiceSwitchedOff_ShouldBeRefused()
        {
            var services = new FakeServices();
            var orders = new FakeOrders();
            var off = new Service("Shirts", 28.9m, 2);
            off.Deactivate();
            services.Items.Add(off);

            var error = await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => CreateOrderService(services, orders)
                    .CreateOrderAsync(Guid.NewGuid(), DropOffOrderFor(off.ServiceId)));

            StringAssert.Contains(error.Message, "currently unavailable");
            Assert.AreEqual(0, orders.Added.Count);
        }

        [TestMethod]
        public async Task PlaceOrder_ForAnActiveService_ShouldBeAccepted()
        {
            var services = new FakeServices();
            var orders = new FakeOrders();
            var on = new Service("Shirts", 28.9m, 2);
            services.Items.Add(on);

            await CreateOrderService(services, orders)
                .CreateOrderAsync(Guid.NewGuid(), DropOffOrderFor(on.ServiceId));

            Assert.AreEqual(1, orders.Added.Count);
        }
    }
}
