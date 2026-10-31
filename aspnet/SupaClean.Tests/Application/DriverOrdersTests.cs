using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.Services;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;

namespace SupaClean.Tests.Application
{
    // The driver's Order charts page must only show orders the driver was given a job for.
    [TestClass]
    public class DriverOrdersTests
    {
        private sealed class FakeOrders : IOrderRepository
        {
            public List<Order> Items { get; } = new();
            public Task<IEnumerable<Order>> GetAllAsync() => Task.FromResult<IEnumerable<Order>>(Items);
            public Task<Order?> GetByIdAsync(Guid id) => throw new NotImplementedException();
            public Task<Order> AddAsync(Order entity) => throw new NotImplementedException();
            public Task Update(Order entity) => throw new NotImplementedException();
            public Task Delete(Order entity) => throw new NotImplementedException();
            public Task<IEnumerable<Order>> GetByCustomerIdAsync(Guid customerId) => throw new NotImplementedException();
            public Task<Order?> GetWithItemsByIdAsync(Guid orderId) => throw new NotImplementedException();
            public Task<IEnumerable<Order>> GetDeliveryStopsAsync() => throw new NotImplementedException();
            public Task<IEnumerable<Order>> GetPendingOrdersAsync() => throw new NotImplementedException();
            public Task<Order?> GetByOrderSequenceAsync(int sequence) => throw new NotImplementedException();
        }

        // Which orders each driver user has been given a job for.
        private sealed class FakeDeliveries : IDeliveryRepository
        {
            public Dictionary<Guid, List<Guid>> OrdersByDriverUser { get; } = new();
            public Task<IReadOnlyList<Guid>> GetOrderIdsForUserAsync(Guid userId)
                => Task.FromResult<IReadOnlyList<Guid>>(OrdersByDriverUser.GetValueOrDefault(userId) ?? new List<Guid>());

            public Task<IReadOnlyList<Delivery>> GetForOrdersAsync(IEnumerable<Guid> orderIds) => throw new NotImplementedException();
            public Task<Delivery?> GetOpenAsync(Guid orderId, DeliveryType type) => throw new NotImplementedException();
            public Task<IReadOnlyList<Delivery>> GetOpenForUserAsync(Guid userId) => throw new NotImplementedException();
            public Task<Delivery?> GetByIdAsync(Guid id) => throw new NotImplementedException();
            public Task<Delivery> AddAsync(Delivery entity) => throw new NotImplementedException();
            public Task<IEnumerable<Delivery>> GetAllAsync() => throw new NotImplementedException();
            public Task Update(Delivery entity) => throw new NotImplementedException();
            public Task Delete(Delivery entity) => throw new NotImplementedException();
        }

        private static Order NewOrder() => new(Guid.NewGuid(), Fulfillment_Method.Delivery, null);

        private static (OrderService Service, FakeOrders Orders, FakeDeliveries Deliveries) Create()
        {
            var orders = new FakeOrders();
            var deliveries = new FakeDeliveries();
            return (new OrderService(orders, null!, null!, null!, null!, null!, deliveries, new NoLoyalty()), orders, deliveries);
        }

        [TestMethod]
        public async Task ADriver_ShouldSeeOnlyTheirOwnOrders()
        {
            var (service, orders, deliveries) = Create();
            var mine1 = NewOrder(); var mine2 = NewOrder(); var someoneElses = NewOrder(); var nobodys = NewOrder();
            orders.Items.AddRange(new[] { mine1, mine2, someoneElses, nobodys });

            var me = Guid.NewGuid(); var other = Guid.NewGuid();
            deliveries.OrdersByDriverUser[me] = new List<Guid> { mine1.OrderId, mine2.OrderId };
            deliveries.OrdersByDriverUser[other] = new List<Guid> { someoneElses.OrderId };

            var result = (await service.GetOrdersForDriverAsync(me)).ToList();

            CollectionAssert.AreEquivalent(new[] { mine1.OrderId, mine2.OrderId }, result.Select(o => o.OrderId).ToList());
        }

        [TestMethod]
        public async Task ADriverWithNoJobs_ShouldSeeNoOrders()
        {
            var (service, orders, _) = Create();
            orders.Items.Add(NewOrder());

            var result = await service.GetOrdersForDriverAsync(Guid.NewGuid());

            Assert.AreEqual(0, result.Count());
        }

        [TestMethod]
        public async Task AnOrderTwoJobsAreForShouldAppearOnce()
        {
            var (service, orders, deliveries) = Create();
            var order = NewOrder();
            orders.Items.Add(order);
            var me = Guid.NewGuid();
            deliveries.OrdersByDriverUser[me] = new List<Guid> { order.OrderId, order.OrderId };

            var result = (await service.GetOrdersForDriverAsync(me)).ToList();

            Assert.AreEqual(1, result.Count);
        }
    }
}
