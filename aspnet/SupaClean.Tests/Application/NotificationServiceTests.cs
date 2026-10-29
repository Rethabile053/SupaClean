using SupaClean.Application.Contracts;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.Services;
using SupaClean.Domain.Entities;

namespace SupaClean.Tests.Application
{
    [TestClass]
    public class NotificationServiceTests
    {
        private sealed class FakeNotifications : INotificationRepository
        {
            public List<Notification> Items { get; } = new();

            public Task<IEnumerable<Notification>> GetByCustomerIdAsync(Guid customerId)
                => Task.FromResult<IEnumerable<Notification>>(
                    Items.Where(n => n.CustomerId == customerId).ToList());

            public Task<Notification?> GetByIdAsync(Guid id)
                => Task.FromResult(Items.FirstOrDefault(n => n.NotificationId == id));
            public Task<Notification> AddAsync(Notification entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<Notification>> GetAllAsync() => Task.FromResult<IEnumerable<Notification>>(Items);
            public Task Update(Notification entity) => Task.CompletedTask;
            public Task Delete(Notification entity) { Items.Remove(entity); return Task.CompletedTask; }
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

        private static (NotificationService Service, FakeNotifications Repo, FakeUnitOfWork Unit) Create()
        {
            var repo = new FakeNotifications();
            var unit = new FakeUnitOfWork();
            return (new NotificationService(repo, unit), repo, unit);
        }

        [TestMethod]
        public async Task Delete_OwnNotification_ShouldRemoveItAndSave()
        {
            var (service, repo, unit) = Create();
            var customer = Guid.NewGuid();
            var n = new Notification(customer, "Order SC-1 cancelled", "Order SC-1 has been cancelled.");
            repo.Items.Add(n);

            await service.DeleteAsync(customer, n.NotificationId);

            Assert.AreEqual(0, repo.Items.Count);
            Assert.AreEqual(1, unit.Saves);
        }

        [TestMethod]
        public async Task Delete_AnotherCustomersNotification_ShouldBeNotFoundAndKeepIt()
        {
            var (service, repo, unit) = Create();
            var owner = Guid.NewGuid();
            var n = new Notification(owner, "Order SC-1 cancelled", "Order SC-1 has been cancelled.");
            repo.Items.Add(n);

            await Assert.ThrowsExactlyAsync<KeyNotFoundException>(
                () => service.DeleteAsync(Guid.NewGuid(), n.NotificationId));

            Assert.AreEqual(1, repo.Items.Count);
            Assert.AreEqual(0, unit.Saves);
        }

        [TestMethod]
        public async Task Delete_ANotificationThatDoesNotExist_ShouldBeNotFound()
        {
            var (service, _, _) = Create();

            await Assert.ThrowsExactlyAsync<KeyNotFoundException>(
                () => service.DeleteAsync(Guid.NewGuid(), Guid.NewGuid()));
        }

        [TestMethod]
        public async Task MarkAsRead_ShouldStayReadWhenListedAgain()
        {
            var (service, repo, _) = Create();
            var customer = Guid.NewGuid();
            var n = new Notification(customer, "Order SC-1 update", "Order SC-1 is now: Washing.");
            repo.Items.Add(n);

            await service.MarkAsReadAsync(customer, n.NotificationId);
            var listed = (await service.GetCustomerNotificationsAsync(customer)).ToList();

            Assert.AreEqual(1, listed.Count);
            Assert.IsTrue(listed[0].IsRead);
        }

        [TestMethod]
        public async Task MarkAllAsRead_ShouldMarkOnlyThisCustomersNotifications()
        {
            var (service, repo, _) = Create();
            var me = Guid.NewGuid();
            var other = Guid.NewGuid();
            repo.Items.Add(new Notification(me, "a", "a"));
            repo.Items.Add(new Notification(me, "b", "b"));
            repo.Items.Add(new Notification(other, "c", "c"));

            await service.MarkAllAsReadAsync(me);

            Assert.IsTrue(repo.Items.Where(n => n.CustomerId == me).All(n => n.IsRead));
            Assert.IsFalse(repo.Items.Single(n => n.CustomerId == other).IsRead);
        }
    }
}
