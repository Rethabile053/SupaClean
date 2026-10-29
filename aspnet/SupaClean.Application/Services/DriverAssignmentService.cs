using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Application.Services
{
    public class DriverAssignmentService : IDriverAssignmentService
    {
        private readonly IOrderRepository _orders;
        private readonly IDeliveryRepository _deliveries;
        private readonly IDriverRepository _drivers;
        private readonly IUserRepository _users;
        private readonly IUnitOfWork _unitOfWork;

        public DriverAssignmentService(IOrderRepository orders, IDeliveryRepository deliveries,
            IDriverRepository drivers, IUserRepository users, IUnitOfWork unitOfWork)
        {
            _orders = orders;
            _deliveries = deliveries;
            _drivers = drivers;
            _users = users;
            _unitOfWork = unitOfWork;
        }

        public async Task<IReadOnlyList<DriverOptionDto>> GetDriversAsync()
            => (await _users.GetByRoleAsync(Role.Driver))
                .Select(u => new DriverOptionDto(u.UserId, FullName(u), u.Email))
                .OrderBy(d => d.FullName, StringComparer.OrdinalIgnoreCase)
                .ToList();

        public async Task<IReadOnlyList<AssignableStopDto>> GetStopsAsync()
        {
            var orders = (await _orders.GetDeliveryStopsAsync()).ToList();
            var jobs = await _deliveries.GetForOrdersAsync(orders.Select(o => o.OrderId));

            var stops = new List<AssignableStopDto>();
            foreach (var o in orders)
            {
                var type = JobTypeOf(o);
                if (type is null) continue;

                var job = jobs.FirstOrDefault(d => d.OrderId == o.OrderId
                                                   && d.DeliveryType == type
                                                   && !d.IsCompleted);
                var driverUser = job?.Driver?.Employee?.User;

                stops.Add(new AssignableStopDto(
                    o.OrderId, o.OrderNumber, o.TicketNumber,
                    type == DeliveryType.Collection ? "Pickup" : "Delivery",
                    $"{o.Customer.User.FirstName} {o.Customer.User.LastName}".Trim(),
                    o.Customer.User.PhoneNumber,
                    o.Customer.City, o.Customer.Address,
                    driverUser?.UserId,
                    driverUser is null ? null : FullName(driverUser)));
            }
            return stops;
        }

        public async Task AssignAsync(Guid orderId, Guid driverUserId)
        {
            var order = await GetOrderAsync(orderId);
            var type = JobTypeOf(order) ?? throw new BusinessRuleException(
                $"Order {order.OrderNumber} is not waiting for a driver. It must be a delivery order that is ready for collection or out for delivery.");

            var user = await _users.GetByIdAsync(driverUserId)
                ?? throw new KeyNotFoundException("That driver was not found.");
            if (user.Role != Role.Driver)
                throw new BusinessRuleException($"{FullName(user)} is not a driver.");

            var driver = await _drivers.GetOrCreateForUserAsync(user);
            var job = await _deliveries.GetOpenAsync(orderId, type);

            if (job is null)
                await _deliveries.AddAsync(new Delivery(orderId, driver.DriverId, type));
            else if (job.DriverId != driver.DriverId)
            {
                job.Reassign(driver);
                await _deliveries.Update(job);
            }
            else
                return;   // already theirs: nothing to save

            await _unitOfWork.SaveChangesAsync();
        }

        public async Task UnassignAsync(Guid orderId)
        {
            var order = await GetOrderAsync(orderId);
            var type = JobTypeOf(order);
            if (type is null) return;

            var job = await _deliveries.GetOpenAsync(orderId, type.Value);
            if (job is null) return;

            if (job.DeliveryStatus != DeliveryStatus.Assigned)
                throw new BusinessRuleException(
                    $"The driver has already started order {order.OrderNumber}, so it cannot be taken away.");

            await _deliveries.Delete(job);
            await _unitOfWork.SaveChangesAsync();
        }

        private async Task<Order> GetOrderAsync(Guid orderId)
            => await _orders.GetByIdAsync(orderId)
               ?? throw new KeyNotFoundException($"Order with ID {orderId} was not found.");

        // What a driver has to do for this order right now, or null when none is needed.
        private static DeliveryType? JobTypeOf(Order order)
        {
            if (order.FulfillmentMethod != Fulfillment_Method.Delivery) return null;
            return order.OrderStatus switch
            {
                OrderStatus.ReadyForCollection => DeliveryType.Collection,
                OrderStatus.OutForDelivery => DeliveryType.Delivery,
                _ => null,
            };
        }

        private static string FullName(User u) => $"{u.FirstName} {u.LastName}".Trim();
    }
}
