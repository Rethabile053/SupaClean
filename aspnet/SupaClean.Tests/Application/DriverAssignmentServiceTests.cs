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
    public class DriverAssignmentServiceTests
    {
        // ---- fakes -------------------------------------------------------

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
            public List<Driver> Items { get; } = new();
            public int Created { get; private set; }

            public Task<Driver?> GetByUserIdAsync(Guid userId)
                => Task.FromResult(Items.FirstOrDefault(d => d.Employee?.UserId == userId));

            public Task<Driver> GetOrCreateForUserAsync(User user)
            {
                var existing = Items.FirstOrDefault(d => d.Employee?.UserId == user.UserId);
                if (existing is not null) return Task.FromResult(existing);

                var employee = new Employee(user.UserId, "Driver");
                SetProp(employee, "User", user);
                var driver = new Driver(employee.EmployeeId, "", user.Email, "Not recorded");
                SetProp(driver, "Employee", employee);
                Items.Add(driver);
                Created++;
                return Task.FromResult(driver);
            }

            public Task<Driver?> GetByIdAsync(Guid id) => Task.FromResult(Items.FirstOrDefault(d => d.DriverId == id));
            public Task<Driver> AddAsync(Driver entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<Driver>> GetAllAsync() => Task.FromResult<IEnumerable<Driver>>(Items);
            public Task Update(Driver entity) => Task.CompletedTask;
            public Task Delete(Driver entity) { Items.Remove(entity); return Task.CompletedTask; }
        }

        private sealed class FakeDeliveries : IDeliveryRepository
        {
            public List<Delivery> Items { get; } = new();
            private readonly FakeDrivers _drivers;
            public FakeDeliveries(FakeDrivers drivers) => _drivers = drivers;

            public Task<IReadOnlyList<Delivery>> GetForOrdersAsync(IEnumerable<Guid> orderIds)
            {
                var ids = orderIds.ToHashSet();
                return Task.FromResult<IReadOnlyList<Delivery>>(Items.Where(d => ids.Contains(d.OrderId)).Select(WithDriver).ToList());
            }

            public Task<Delivery?> GetOpenAsync(Guid orderId, DeliveryType type)
                => Task.FromResult(Items.Where(d => d.OrderId == orderId && d.DeliveryType == type && !d.IsCompleted)
                                        .Select(WithDriver).FirstOrDefault());

            public Task<IReadOnlyList<Delivery>> GetOpenForUserAsync(Guid userId)
                => Task.FromResult<IReadOnlyList<Delivery>>(Items.Where(d => !d.IsCompleted)
                    .Select(WithDriver).Where(d => d.Driver.Employee.UserId == userId).ToList());

            // The real repository loads the driver; the fake fills it in the same way.
            private Delivery WithDriver(Delivery d)
            {
                if (d.Driver is null)
                    SetProp(d, "Driver", _drivers.Items.First(x => x.DriverId == d.DriverId));
                return d;
            }

            public Task<Delivery?> GetByIdAsync(Guid id) => Task.FromResult(Items.FirstOrDefault(d => d.DeliveryId == id));
            public Task<Delivery> AddAsync(Delivery entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<Delivery>> GetAllAsync() => Task.FromResult<IEnumerable<Delivery>>(Items);
            public Task Update(Delivery entity) => Task.CompletedTask;
            public Task Delete(Delivery entity) { Items.Remove(entity); return Task.CompletedTask; }
        }

        private sealed class FakeOrders : IOrderRepository
        {
            public List<Order> Items { get; } = new();
            public Task<Order?> GetByIdAsync(Guid id) => Task.FromResult(Items.FirstOrDefault(o => o.OrderId == id));
            public Task<IEnumerable<Order>> GetDeliveryStopsAsync()
                => Task.FromResult<IEnumerable<Order>>(Items.Where(o => o.FulfillmentMethod == Fulfillment_Method.Delivery
                    && (o.OrderStatus == OrderStatus.ReadyForCollection || o.OrderStatus == OrderStatus.OutForDelivery)).ToList());
            public Task<Order> AddAsync(Order entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<Order>> GetAllAsync() => throw new NotImplementedException();
            public Task Update(Order entity) => Task.CompletedTask;
            public Task Delete(Order entity) => throw new NotImplementedException();
            public Task<IEnumerable<Order>> GetByCustomerIdAsync(Guid customerId) => throw new NotImplementedException();
            public Task<Order?> GetWithItemsByIdAsync(Guid orderId) => throw new NotImplementedException();
            public Task<IEnumerable<Order>> GetPendingOrdersAsync() => throw new NotImplementedException();
            public Task<Order?> GetByOrderSequenceAsync(int sequence) => throw new NotImplementedException();
        }

        private sealed class FakePayments : IPayment
        {
            public Dictionary<(Guid, PaymentType), Payment> Items { get; } = new();
            public Task<Payment?> GetByOrderIdAndTypeAsync(Guid orderId, PaymentType type)
                => Task.FromResult(Items.GetValueOrDefault((orderId, type)));
            public Task<Payment?> GetByIdAsync(Guid id) => throw new NotImplementedException();
            public Task<Payment> AddAsync(Payment entity) { Items[(entity.OrderId, entity.PaymentType)] = entity; return Task.FromResult(entity); }
            public Task<IEnumerable<Payment>> GetAllAsync() => throw new NotImplementedException();
            public Task Update(Payment entity) => Task.CompletedTask;
            public Task Delete(Payment entity) => throw new NotImplementedException();
            public Task<IEnumerable<Payment>> GetUnverifiedPaymentsAsync() => throw new NotImplementedException();
            public Task<IEnumerable<Payment>> GetAllWithDetailsAsync() => throw new NotImplementedException();
            public Task<IEnumerable<Payment>> GetByOrderIdAsync(Guid orderId) => throw new NotImplementedException();
        }

        private sealed class FakeNotifications : SupaClean.Application.Contracts.INotificationRepository
        {
            public List<Notification> Items { get; } = new();
            public Task<IEnumerable<Notification>> GetByCustomerIdAsync(Guid customerId) => Task.FromResult<IEnumerable<Notification>>(Items);
            public Task<Notification?> GetByIdAsync(Guid id) => Task.FromResult(Items.FirstOrDefault(n => n.NotificationId == id));
            public Task<Notification> AddAsync(Notification entity) { Items.Add(entity); return Task.FromResult(entity); }
            public Task<IEnumerable<Notification>> GetAllAsync() => Task.FromResult<IEnumerable<Notification>>(Items);
            public Task Update(Notification entity) => Task.CompletedTask;
            public Task Delete(Notification entity) => Task.CompletedTask;
        }

        private sealed class FakeUnitOfWork : IUnitOfWork
        {
            public int Saves { get; private set; }
            public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) { Saves++; return Task.FromResult(1); }
        }

        private static void SetProp(object target, string name, object? value)
            => target.GetType().GetProperty(name, BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance)!
                     .SetValue(target, value);

        // ---- setup -------------------------------------------------------

        private sealed class Setup
        {
            public FakeUsers Users = new();
            public FakeDrivers Drivers = new();
            public FakeDeliveries Deliveries;
            public FakeOrders Orders = new();
            public FakeUnitOfWork Unit = new();
            public DriverAssignmentService Service;

            public Setup()
            {
                Deliveries = new FakeDeliveries(Drivers);
                Service = new DriverAssignmentService(Orders, Deliveries, Drivers, Users, Unit);
            }

            public User AddUser(string first, Role role)
            {
                var u = new User(Guid.NewGuid(), first, "Test", $"{first.ToLower()}@example.com", "0821234567", role);
                Users.Items.Add(u);
                return u;
            }

            public Order AddOrder(OrderStatus status, Fulfillment_Method method = Fulfillment_Method.Delivery)
            {
                var customerUser = new User(Guid.NewGuid(), "Cara", "Customer", "cara@example.com", "0711111111");
                var customer = new Customer(customerUser, "Bloemfontein", "12 Main Road");
                var order = new Order(customer.CustomerId, method, null);
                SetProp(order, "Customer", customer);
                SetProp(customer, "User", customerUser);
                order.UpdateStatus(status);
                Orders.Items.Add(order);
                return order;
            }
        }

        // ---- drivers -----------------------------------------------------

        [TestMethod]
        public async Task GetDrivers_ShouldListOnlyPeopleWithTheDriverRole_ByName()
        {
            var s = new Setup();
            s.AddUser("Zed", Role.Driver);
            s.AddUser("Amy", Role.Driver);
            s.AddUser("Bob", Role.Customer);
            s.AddUser("Ann", Role.Admin);

            var drivers = await s.Service.GetDriversAsync();

            CollectionAssert.AreEqual(new[] { "Amy Test", "Zed Test" }, drivers.Select(d => d.FullName).ToArray());
        }

        [TestMethod]
        public async Task GetDrivers_ShouldSayHowManyOpenJobsEachHas()
        {
            var s = new Setup();
            var dan = s.AddUser("Dan", Role.Driver);
            var eve = s.AddUser("Eve", Role.Driver);
            var first = s.AddOrder(OrderStatus.OutForDelivery);
            var second = s.AddOrder(OrderStatus.ReadyForCollection);
            await s.Service.AssignAsync(first.OrderId, dan.UserId);
            await s.Service.AssignAsync(second.OrderId, dan.UserId);

            var drivers = await s.Service.GetDriversAsync();

            Assert.AreEqual(2, drivers.Single(d => d.UserId == dan.UserId).OpenJobs);
            Assert.AreEqual(0, drivers.Single(d => d.UserId == eve.UserId).OpenJobs);
        }

        [TestMethod]
        public async Task GetDrivers_AFinishedJobIsNotCounted()
        {
            var s = new Setup();
            var dan = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.OutForDelivery);
            await s.Service.AssignAsync(order.OrderId, dan.UserId);
            s.Deliveries.Items.Single().MarkCompleted();

            var drivers = await s.Service.GetDriversAsync();

            Assert.AreEqual(0, drivers.Single().OpenJobs);
        }

        // ---- assigning ---------------------------------------------------

        [TestMethod]
        public async Task Assign_ThePickupOfAnOrderReadyForCollection_ShouldCreateACollectionJob()
        {
            var s = new Setup();
            var driver = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.ReadyForCollection);

            await s.Service.AssignAsync(order.OrderId, driver.UserId);

            var job = s.Deliveries.Items.Single();
            Assert.AreEqual(order.OrderId, job.OrderId);
            Assert.AreEqual(DeliveryType.Collection, job.DeliveryType);
            Assert.AreEqual(s.Drivers.Items.Single().DriverId, job.DriverId);
            Assert.AreEqual(1, s.Unit.Saves);
        }

        [TestMethod]
        public async Task Assign_AnOrderOutForDelivery_ShouldCreateADeliveryJob()
        {
            var s = new Setup();
            var driver = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.OutForDelivery);

            await s.Service.AssignAsync(order.OrderId, driver.UserId);

            Assert.AreEqual(DeliveryType.Delivery, s.Deliveries.Items.Single().DeliveryType);
        }

        [TestMethod]
        public async Task Assign_TheSameDriverTwice_ShouldNotAddOrSaveAgain()
        {
            var s = new Setup();
            var driver = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.OutForDelivery);

            await s.Service.AssignAsync(order.OrderId, driver.UserId);
            await s.Service.AssignAsync(order.OrderId, driver.UserId);

            Assert.AreEqual(1, s.Deliveries.Items.Count);
            Assert.AreEqual(1, s.Drivers.Created);
            Assert.AreEqual(1, s.Unit.Saves);
        }

        [TestMethod]
        public async Task Assign_ADifferentDriver_ShouldMoveTheSameJob()
        {
            var s = new Setup();
            var first = s.AddUser("Dan", Role.Driver);
            var second = s.AddUser("Eve", Role.Driver);
            var order = s.AddOrder(OrderStatus.OutForDelivery);

            await s.Service.AssignAsync(order.OrderId, first.UserId);
            await s.Service.AssignAsync(order.OrderId, second.UserId);

            var job = s.Deliveries.Items.Single();
            Assert.AreEqual(s.Drivers.Items.Single(d => d.Employee.UserId == second.UserId).DriverId, job.DriverId);
            Assert.AreEqual(2, s.Unit.Saves);
        }

        [TestMethod]
        public async Task Assign_AUserWhoIsNotADriver_ShouldBeRefusedAndSaveNothing()
        {
            var s = new Setup();
            var customer = s.AddUser("Cat", Role.Customer);
            var order = s.AddOrder(OrderStatus.OutForDelivery);

            var error = await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => s.Service.AssignAsync(order.OrderId, customer.UserId));

            StringAssert.Contains(error.Message, "is not a driver");
            Assert.AreEqual(0, s.Deliveries.Items.Count);
            Assert.AreEqual(0, s.Unit.Saves);
        }

        [TestMethod]
        public async Task Assign_AnOrderNotWaitingForADriver_ShouldBeRefused()
        {
            var s = new Setup();
            var driver = s.AddUser("Dan", Role.Driver);
            var washing = s.AddOrder(OrderStatus.Washing);
            var dropOff = s.AddOrder(OrderStatus.OutForDelivery, Fulfillment_Method.DropOff);

            foreach (var order in new[] { washing, dropOff })
            {
                var error = await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                    () => s.Service.AssignAsync(order.OrderId, driver.UserId));
                StringAssert.Contains(error.Message, "not waiting for a driver");
            }
            Assert.AreEqual(0, s.Unit.Saves);
        }

        [TestMethod]
        public async Task Assign_AnUnknownOrderOrDriver_ShouldBeNotFound()
        {
            var s = new Setup();
            var driver = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.OutForDelivery);

            await Assert.ThrowsExactlyAsync<KeyNotFoundException>(
                () => s.Service.AssignAsync(Guid.NewGuid(), driver.UserId));
            await Assert.ThrowsExactlyAsync<KeyNotFoundException>(
                () => s.Service.AssignAsync(order.OrderId, Guid.NewGuid()));
        }

        // ---- unassigning -------------------------------------------------

        [TestMethod]
        public async Task Unassign_ShouldTakeTheJobAway()
        {
            var s = new Setup();
            var driver = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.OutForDelivery);
            await s.Service.AssignAsync(order.OrderId, driver.UserId);

            await s.Service.UnassignAsync(order.OrderId);

            Assert.AreEqual(0, s.Deliveries.Items.Count);
        }

        [TestMethod]
        public async Task Unassign_WhenNobodyHasIt_ShouldDoNothing()
        {
            var s = new Setup();
            var order = s.AddOrder(OrderStatus.OutForDelivery);

            await s.Service.UnassignAsync(order.OrderId);

            Assert.AreEqual(0, s.Unit.Saves);
        }

        [TestMethod]
        public async Task Unassign_ByTheTimeTheDriverHasStarted_ShouldBeRefused()
        {
            var s = new Setup();
            var driver = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.OutForDelivery);
            await s.Service.AssignAsync(order.OrderId, driver.UserId);
            SetProp(s.Deliveries.Items.Single(), "DeliveryStatus", DeliveryStatus.InTransit);

            var error = await Assert.ThrowsExactlyAsync<BusinessRuleException>(
                () => s.Service.UnassignAsync(order.OrderId));

            StringAssert.Contains(error.Message, "already started");
            Assert.AreEqual(1, s.Deliveries.Items.Count);
        }

        // ---- what a driver sees, and finishing a job ----------------------

        private static (DeliveryService Service, FakePayments Payments) DriverSide(Setup s)
        {
            var payments = new FakePayments();
            return (new DeliveryService(s.Orders, payments, new FakeNotifications(), s.Deliveries, s.Unit), payments);
        }

        [TestMethod]
        public async Task DriverStops_ForADriver_ShouldBeOnlyTheOrdersGivenToThem()
        {
            var s = new Setup();
            var dan = s.AddUser("Dan", Role.Driver);
            var mine = s.AddOrder(OrderStatus.OutForDelivery);
            var theirs = s.AddOrder(OrderStatus.OutForDelivery);
            var eve = s.AddUser("Eve", Role.Driver);
            await s.Service.AssignAsync(mine.OrderId, dan.UserId);
            await s.Service.AssignAsync(theirs.OrderId, eve.UserId);
            var (delivery, _) = DriverSide(s);

            var forDan = (await delivery.GetStopsAsync(dan.UserId)).ToList();
            var everyone = (await delivery.GetStopsAsync()).ToList();

            CollectionAssert.AreEqual(new[] { mine.OrderId }, forDan.Select(x => x.OrderId).ToArray());
            Assert.AreEqual(2, everyone.Count);   // no driver given: all of them, as before
        }

        [TestMethod]
        public async Task DriverStops_AnOrderNobodyIsGiven_ShouldNotShowForADriver()
        {
            var s = new Setup();
            var dan = s.AddUser("Dan", Role.Driver);
            s.AddOrder(OrderStatus.OutForDelivery);
            var (delivery, _) = DriverSide(s);

            Assert.AreEqual(0, (await delivery.GetStopsAsync(dan.UserId)).Count());
        }

        [TestMethod]
        public async Task DriverStops_APickupJobDoesNotCarryOverToTheDelivery()
        {
            var s = new Setup();
            var dan = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.ReadyForCollection);
            await s.Service.AssignAsync(order.OrderId, dan.UserId);
            var (delivery, _) = DriverSide(s);
            Assert.AreEqual(1, (await delivery.GetStopsAsync(dan.UserId)).Count());

            // Later the order comes back for delivery; the pickup job was Dan's, not the delivery.
            order.UpdateStatus(OrderStatus.OutForDelivery);

            Assert.AreEqual(0, (await delivery.GetStopsAsync(dan.UserId)).Count());
        }

        [TestMethod]
        public async Task MarkDelivered_ShouldFinishTheDriversJob()
        {
            var s = new Setup();
            var dan = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.OutForDelivery);
            await s.Service.AssignAsync(order.OrderId, dan.UserId);
            var (delivery, payments) = DriverSide(s);
            var pay = new Payment(order.OrderId, PaymentType.Orderpayment, 100m, PaymentMethod.CashOnDelivery);
            pay.MarkCashCollected(Guid.NewGuid(), 100m);
            await payments.AddAsync(pay);

            await delivery.MarkDeliveredAsync(order.OrderId);

            var job = s.Deliveries.Items.Single();
            Assert.IsTrue(job.IsCompleted);
            Assert.AreEqual(DeliveryStatus.Delivered, job.DeliveryStatus);
            Assert.AreEqual(OrderStatus.Completed, order.OrderStatus);
        }

        [TestMethod]
        public async Task MarkCollected_ShouldFinishThePickupJob()
        {
            var s = new Setup();
            var dan = s.AddUser("Dan", Role.Driver);
            var order = s.AddOrder(OrderStatus.ReadyForCollection);
            await s.Service.AssignAsync(order.OrderId, dan.UserId);
            var (delivery, payments) = DriverSide(s);
            var fee = new Payment(order.OrderId, PaymentType.DeliveryFee, 50m, PaymentMethod.EFT, "ref", "proof.pdf");
            fee.Verify(Guid.NewGuid());
            await payments.AddAsync(fee);

            await delivery.MarkCollectedAsync(order.OrderId);

            var job = s.Deliveries.Items.Single();
            Assert.IsTrue(job.IsCompleted);
            Assert.AreEqual(DeliveryStatus.Collected, job.DeliveryStatus);
            Assert.AreEqual(OrderStatus.Collected, order.OrderStatus);
        }

        [TestMethod]
        public async Task MarkDelivered_ForAnOrderNobodyWasGiven_ShouldStillWork()
        {
            var s = new Setup();
            var order = s.AddOrder(OrderStatus.OutForDelivery);
            var (delivery, payments) = DriverSide(s);
            var pay = new Payment(order.OrderId, PaymentType.Orderpayment, 100m, PaymentMethod.CashOnDelivery);
            pay.MarkCashCollected(Guid.NewGuid(), 100m);
            await payments.AddAsync(pay);

            await delivery.MarkDeliveredAsync(order.OrderId);

            Assert.AreEqual(OrderStatus.Completed, order.OrderStatus);
        }

        // ---- listing -----------------------------------------------------

        [TestMethod]
        public async Task GetStops_ShouldShowWhoHasEachOrder()
        {
            var s = new Setup();
            var driver = s.AddUser("Dan", Role.Driver);
            var taken = s.AddOrder(OrderStatus.OutForDelivery);
            var free = s.AddOrder(OrderStatus.ReadyForCollection);
            s.AddOrder(OrderStatus.Washing);   // not a stop
            await s.Service.AssignAsync(taken.OrderId, driver.UserId);

            var stops = await s.Service.GetStopsAsync();

            Assert.AreEqual(2, stops.Count);
            var takenStop = stops.Single(x => x.OrderId == taken.OrderId);
            Assert.AreEqual("Delivery", takenStop.StopType);
            Assert.AreEqual(driver.UserId, takenStop.AssignedDriverUserId);
            Assert.AreEqual("Dan Test", takenStop.AssignedDriverName);
            var freeStop = stops.Single(x => x.OrderId == free.OrderId);
            Assert.AreEqual("Pickup", freeStop.StopType);
            Assert.IsNull(freeStop.AssignedDriverUserId);
            Assert.AreEqual("Cara Customer", freeStop.CustomerName);
        }
    }
}
