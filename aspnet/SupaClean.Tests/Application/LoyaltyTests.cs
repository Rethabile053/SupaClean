using SupaClean.Application.Contracts;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Application.Services;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using SupaClean.Domain.Rules;

namespace SupaClean.Tests.Application
{
    // Stands in for the points service where a test is about something else.
    internal sealed class NoLoyalty : ILoyaltyService
    {
        public Task<PointsSummaryDto> GetSummaryAsync(Guid customerId)
            => Task.FromResult(new PointsSummaryDto(0, 0, 10, 2, 0.5m, new()));
        public Task<decimal> RedeemForNewOrderAsync(Order order) => Task.FromResult(0m);
        public Task AwardForCompletedOrderAsync(Order order) => Task.CompletedTask;
        public Task RefundForOrderAsync(Order order) => Task.CompletedTask;
    }

    [TestClass]
    public class LoyaltyTests
    {
        private sealed class FakePoints : IPointsRepository
        {
            public List<PointsTransaction> Items { get; } = new();

            public Task<int> GetBalanceAsync(Guid customerId)
                => Task.FromResult(Items.Where(t => t.CustomerId == customerId).Sum(t => t.Points));
            public Task<IReadOnlyList<PointsTransaction>> GetHistoryAsync(Guid customerId)
                => Task.FromResult<IReadOnlyList<PointsTransaction>>(
                    Items.Where(t => t.CustomerId == customerId).OrderByDescending(t => t.CreatedAt).ToList());
            public Task<bool> ExistsAsync(Guid orderId, PointsKind kind)
                => Task.FromResult(Items.Any(t => t.OrderId == orderId && t.Kind == kind));
            public Task<int> SumForOrderAsync(Guid orderId, PointsKind kind)
                => Task.FromResult(Items.Where(t => t.OrderId == orderId && t.Kind == kind).Sum(t => t.Points));
            public Task<PointsTransaction?> GetByIdAsync(Guid id)
                => Task.FromResult(Items.FirstOrDefault(t => t.PointsTransactionId == id));
            public Task<PointsTransaction> AddAsync(PointsTransaction entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<PointsTransaction>> GetAllAsync() => Task.FromResult<IEnumerable<PointsTransaction>>(Items);
            public Task Update(PointsTransaction entity) => Task.CompletedTask;
            public Task Delete(PointsTransaction entity) => Task.CompletedTask;
        }

        private sealed class FakeNotifications : INotificationRepository
        {
            public List<Notification> Items { get; } = new();
            public Task<IEnumerable<Notification>> GetByCustomerIdAsync(Guid customerId)
                => Task.FromResult<IEnumerable<Notification>>(Items.Where(n => n.CustomerId == customerId).ToList());
            public Task<Notification?> GetByIdAsync(Guid id) => Task.FromResult(Items.FirstOrDefault(n => n.NotificationId == id));
            public Task<Notification> AddAsync(Notification entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<Notification>> GetAllAsync() => Task.FromResult<IEnumerable<Notification>>(Items);
            public Task Update(Notification entity) => Task.CompletedTask;
            public Task Delete(Notification entity) => Task.CompletedTask;
        }

        private static (LoyaltyService, FakePoints, FakeNotifications) Create()
        {
            var points = new FakePoints();
            var notes = new FakeNotifications();
            return (new LoyaltyService(points, notes), points, notes);
        }

        // An order worth R200 in laundry.
        private static Order OrderFor(Guid customerId, decimal items = 200m)
        {
            var order = new Order(customerId, Fulfillment_Method.DropOff);
            order.AddOrderItem(Guid.NewGuid(), 1, items);
            return order;
        }

        // ---- the rules ----

        [TestMethod]
        public void Earn_OnePointForEveryTwoRandPaid()
        {
            Assert.AreEqual(100, LoyaltyRules.PointsEarned(200m));
            Assert.AreEqual(37, LoyaltyRules.PointsEarned(75m));   // part of R2 earns nothing
            Assert.AreEqual(0, LoyaltyRules.PointsEarned(1.99m));
            Assert.AreEqual(0, LoyaltyRules.PointsEarned(0m));
        }

        [TestMethod]
        public void Redeem_TenPointsAreOneRand()
        {
            Assert.AreEqual(12m, LoyaltyRules.RandValue(125));
            Assert.AreEqual(0m, LoyaltyRules.RandValue(9));
            Assert.AreEqual(120, LoyaltyRules.PointsFor(12m));
        }

        [TestMethod]
        public void MaxDiscount_IsLimitedByBalanceAndByHalfTheLaundry()
        {
            Assert.AreEqual(12m, LoyaltyRules.MaxDiscount(200m, 120));     // balance is the limit
            Assert.AreEqual(100m, LoyaltyRules.MaxDiscount(200m, 5000));   // half the laundry is the limit
            Assert.AreEqual(0m, LoyaltyRules.MaxDiscount(200m, 0));
            Assert.AreEqual(0m, LoyaltyRules.MaxDiscount(0m, 500));
        }

        // ---- the order ----

        [TestMethod]
        public void Order_PointsDiscountLowersTheTotalAndThePaymentDue()
        {
            var order = OrderFor(Guid.NewGuid(), 200m);
            order.SetHomePickup(30m);

            order.ApplyPointsDiscount(20m);

            Assert.AreEqual(210m, order.OrderPaymentDue);   // 200 + 30 - 20
            Assert.AreEqual(210m, order.GrandTotal);
            Assert.AreEqual(20m, order.PointsDiscount);
        }

        [TestMethod]
        public void Order_PointsDiscount_RejectsBadAmounts()
        {
            var order = OrderFor(Guid.NewGuid(), 100m);

            Assert.ThrowsExactly<BusinessRuleException>(() => order.ApplyPointsDiscount(0m));
            Assert.ThrowsExactly<BusinessRuleException>(() => order.ApplyPointsDiscount(2.5m));
            Assert.ThrowsExactly<BusinessRuleException>(() => order.ApplyPointsDiscount(100m));
        }

        // ---- the service ----

        [TestMethod]
        public async Task Redeem_TakesTheDiscountOffAndRecordsTheSpentPoints()
        {
            var (svc, points, _) = Create();
            var customer = Guid.NewGuid();
            await points.AddAsync(new PointsTransaction(customer, null, PointsKind.Earned, 120, "Earlier order"));
            var order = OrderFor(customer);

            var rand = await svc.RedeemForNewOrderAsync(order);

            Assert.AreEqual(12m, rand);
            Assert.AreEqual(12m, order.PointsDiscount);
            Assert.AreEqual(0, await points.GetBalanceAsync(customer));
        }

        [TestMethod]
        public async Task Redeem_WithNoPoints_ChangesNothing()
        {
            var (svc, points, _) = Create();
            var customer = Guid.NewGuid();
            var order = OrderFor(customer);

            Assert.AreEqual(0m, await svc.RedeemForNewOrderAsync(order));
            Assert.AreEqual(0m, order.PointsDiscount);
            Assert.AreEqual(0, points.Items.Count);
        }

        [TestMethod]
        public async Task Redeem_NeverCoversMoreThanHalfTheLaundry()
        {
            var (svc, points, _) = Create();
            var customer = Guid.NewGuid();
            await points.AddAsync(new PointsTransaction(customer, null, PointsKind.Earned, 5000, "Lots"));
            var order = OrderFor(customer, 100m);

            await svc.RedeemForNewOrderAsync(order);

            Assert.AreEqual(50m, order.PointsDiscount);
            Assert.AreEqual(4500, await points.GetBalanceAsync(customer));   // only 500 points were spent
        }

        [TestMethod]
        public async Task Award_GivesPointsOnceFromWhatWasPaid()
        {
            var (svc, points, notes) = Create();
            var customer = Guid.NewGuid();
            var order = OrderFor(customer, 200m);
            order.ApplyPointsDiscount(20m);   // paid R180

            await svc.AwardForCompletedOrderAsync(order);
            await svc.AwardForCompletedOrderAsync(order);   // a second call must not pay out again

            Assert.AreEqual(90, await points.GetBalanceAsync(customer));
            Assert.AreEqual(1, notes.Items.Count);
        }

        [TestMethod]
        public async Task Refund_ReturnsSpentPointsOnce()
        {
            var (svc, points, notes) = Create();
            var customer = Guid.NewGuid();
            await points.AddAsync(new PointsTransaction(customer, null, PointsKind.Earned, 120, "Earlier order"));
            var order = OrderFor(customer);
            await svc.RedeemForNewOrderAsync(order);

            await svc.RefundForOrderAsync(order);
            await svc.RefundForOrderAsync(order);

            Assert.AreEqual(120, await points.GetBalanceAsync(customer));
            Assert.AreEqual(1, notes.Items.Count);
        }

        [TestMethod]
        public async Task Refund_WhenNoPointsWereUsed_DoesNothing()
        {
            var (svc, points, notes) = Create();
            var order = OrderFor(Guid.NewGuid());

            await svc.RefundForOrderAsync(order);

            Assert.AreEqual(0, points.Items.Count);
            Assert.AreEqual(0, notes.Items.Count);
        }

        [TestMethod]
        public async Task Summary_ShowsBalanceValueRulesAndHistory()
        {
            var (svc, points, _) = Create();
            var customer = Guid.NewGuid();
            await points.AddAsync(new PointsTransaction(customer, null, PointsKind.Earned, 135, "Order delivered"));

            var summary = await svc.GetSummaryAsync(customer);

            Assert.AreEqual(135, summary.Balance);
            Assert.AreEqual(13m, summary.BalanceValue);
            Assert.AreEqual(10, summary.PointsPerRand);
            Assert.AreEqual(1, summary.History.Count);
        }

        [TestMethod]
        public void Transaction_RejectsWrongSigns()
        {
            var c = Guid.NewGuid();
            Assert.ThrowsExactly<BusinessRuleException>(() => new PointsTransaction(c, null, PointsKind.Redeemed, 10, "x"));
            Assert.ThrowsExactly<BusinessRuleException>(() => new PointsTransaction(c, null, PointsKind.Earned, -10, "x"));
            Assert.ThrowsExactly<BusinessRuleException>(() => new PointsTransaction(c, null, PointsKind.Earned, 0, "x"));
        }
    }
}
