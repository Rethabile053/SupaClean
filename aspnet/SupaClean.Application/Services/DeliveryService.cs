using SupaClean.Application.Contracts;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Services
{
    public class DeliveryService : IDeliveryService
    {
        private readonly IOrderRepository _orders;
        private readonly IPayment _payments;
        private readonly INotificationRepository _notifications;
        private readonly IUnitOfWork _unitOfWork;

        public DeliveryService(IOrderRepository orders, IPayment payments,
                               INotificationRepository notifications, IUnitOfWork unitOfWork)
        {
            _orders = orders;
            _payments = payments;
            _notifications = notifications;
            _unitOfWork = unitOfWork;
        }

        public async Task<IEnumerable<DriverStopDto>> GetStopsAsync()
        {
            var orders = await _orders.GetDeliveryStopsAsync();
            var stops = new List<DriverStopDto>();

            foreach (var o in orders)
            {
                var isPickup = o.OrderStatus == OrderStatus.ReadyForCollection;
                string? method = null;
                decimal due = 0;

                if (!isPickup)
                {
                    var pay = await _payments.GetByOrderIdAndTypeAsync(o.OrderId, PaymentType.Orderpayment);
                    method = pay?.PaymentMethod.ToString() ?? "NotSelected";
                    due = pay?.PaymentStatus == PaymentStatus.Paid ? 0 : (pay?.Amount ?? o.ItemsTotal);
                }

                stops.Add(new DriverStopDto(
                    o.OrderId, o.OrderNumber, isPickup ? "Pickup" : "Delivery",
                    $"{o.Customer.User.FirstName} {o.Customer.User.LastName}",
                    o.Customer.User.PhoneNumber,
                    o.Customer.City, o.Customer.Address,
                    o.SpecialInstructions, method, due));
            }
            return stops;
        }

        public async Task MarkCollectedAsync(Guid orderId)
        {
            var order = await GetDeliveryOrderAsync(orderId, OrderStatus.ReadyForCollection);

            var fee = await _payments.GetByOrderIdAndTypeAsync(orderId, PaymentType.DeliveryFee);
            if (fee?.PaymentStatus != PaymentStatus.Paid)
                throw new BusinessRuleException("The delivery fee must be paid before pickup.");

            order.UpdateStatus(OrderStatus.Collected);
            await _notifications.AddAsync(new Notification(order.CustomerId,
                $"Order {order.OrderNumber} collected",
                "Your laundry has been collected and is on its way to be cleaned.", order.OrderId));

            await _orders.Update(order);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task RecordCashCollectedAsync(Guid orderId, Guid driverId, decimal amount)
        {
            var order = await GetDeliveryOrderAsync(orderId, OrderStatus.OutForDelivery);

            var payment = await _payments.GetByOrderIdAndTypeAsync(orderId, PaymentType.Orderpayment);
            if (payment is null)
            {
                // the customer never submitted a payment: record it as cash on delivery now
                payment = new Payment(orderId, PaymentType.Orderpayment, order.ItemsTotal, PaymentMethod.CashOnDelivery);
                await _payments.AddAsync(payment);
            }

            payment.MarkCashCollected(driverId, amount);
            await _notifications.AddAsync(new Notification(order.CustomerId, "Payment received",
                $"We received R{amount:0.00} for order {order.OrderNumber}.", order.OrderId));

            await _payments.Update(payment);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task MarkDeliveredAsync(Guid orderId)
        {
            var order = await GetDeliveryOrderAsync(orderId, OrderStatus.OutForDelivery);

            var payment = await _payments.GetByOrderIdAndTypeAsync(orderId, PaymentType.Orderpayment);
            if (payment?.PaymentStatus != PaymentStatus.Paid)
                throw new BusinessRuleException("The order must be paid before it is handed back.");

            order.UpdateStatus(OrderStatus.Completed);
            await _notifications.AddAsync(new Notification(order.CustomerId,
                $"Order {order.OrderNumber} delivered",
                "Your laundry has been delivered. Thank you for choosing SupaClean!", order.OrderId));

            await _orders.Update(order);
            await _unitOfWork.SaveChangesAsync();
        }

        private async Task<Order> GetDeliveryOrderAsync(Guid orderId, OrderStatus expected)
        {
            var order = await _orders.GetByIdAsync(orderId)
                ?? throw new KeyNotFoundException($"Order with ID {orderId} was not found.");
            if (order.FulfillmentMethod != Fulfillment_Method.Delivery)
                throw new BusinessRuleException("This is not a delivery order.");
            if (order.OrderStatus != expected)
                throw new BusinessRuleException($"The order must be '{expected}', but it is '{order.OrderStatus}'.");
            return order;
        }
    }
}
