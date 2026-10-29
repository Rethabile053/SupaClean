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
    public  class OrderService:IOrderService
    {
        private readonly IOrderRepository _orderRepository;
        private readonly IServiceRepository _serviceRepository;
        private readonly IDeliveryZoneRepository _deliveryZoneRepository;
        private readonly INotificationRepository _notifications;
        private readonly IPayment _paymentRepository;
        private readonly IUnitOfWork _unitOfWork;

        public OrderService(IOrderRepository orderRepository, IServiceRepository serviceRepository,IDeliveryZoneRepository deliveryZoneRepository,INotificationRepository notifications ,IPayment paymentRepository,IUnitOfWork unitOfWork)
        {
            _orderRepository = orderRepository;
            _serviceRepository = serviceRepository;
            _deliveryZoneRepository = deliveryZoneRepository;
            _notifications = notifications;
            _paymentRepository = paymentRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Guid> CreateOrderAsync(Guid customerId, CreateOrderDTO dto)
        {
            //  Instantiate the Rich Domain Entity 
            if (!Enum.TryParse<Fulfillment_Method>(dto.FulfillmentMethod, true, out var method))
                throw new BusinessRuleException("Invalid fulfillment method.");

            var order = new Order(customerId, method, dto.SpecialInstructions);
            order.SetSchedule(dto.PickupDate, dto.DeliveryDate);

            //  Add line items using the Domain Method on the Aggregate Root
            foreach (var item in dto.Items)
            {
                // order.AddOrderItem internally recalculates total amount and validates pricing/quantity
                order.AddOrderItem(item.ServiceId, item.Quantity, item.UnitPrice, item.Description);
            }
            // Delivery and home pickup are both charged by the customer's area.
            if (method == Fulfillment_Method.Delivery || dto.HomePickup)
            {
                if (dto.DeliveryZoneId is null)
                    throw new BusinessRuleException("Please select your delivery area.");

                var zone = await _deliveryZoneRepository.GetByIdAsync(dto.DeliveryZoneId.Value)
                    ?? throw new BusinessRuleException("Delivery area not found.");
                if (!zone.IsActive)
                    throw new BusinessRuleException($"We are not currently delivering to {zone.Name}.");

                if (dto.HomePickup)
                    order.SetHomePickup(zone.Fee);
                if (method == Fulfillment_Method.Delivery)
                    order.SetDeliveryZone(zone.ZoneId, zone.Fee);
            }

            //  Persist through Repository & Unit of Work
            await _orderRepository.AddAsync(order);
            await _unitOfWork.SaveChangesAsync();

            return order.OrderId;
        }

        public async Task LinkPhysicalTicketAsync(Guid orderId, string ticketNumber)
        {
            var order = await _orderRepository.GetByIdAsync(orderId)
                ?? throw new KeyNotFoundException($"Order with ID {orderId} was not found.");

            // Domain method handles linking state
            order.LinkPhysicalTicket(ticketNumber);

            _orderRepository.Update(order);
            await _unitOfWork.SaveChangesAsync();
        }
      
      
        
        public async Task<OrderDto?> GetOrderByIdAsync(Guid orderId)
        {
            var order = await _orderRepository.GetByIdAsync(orderId);
            if (order == null) return null;

            return MapToDto(order);
        }
        public async Task<IEnumerable<OrderDto>> GetAllOrdersAsync()
    => (await _orderRepository.GetAllAsync()).OrderByDescending(o => o.OrderDate).Select(MapToDto);

        public async Task<OrderDto?> GetOrderByNumberAsync(string orderNumber)
        {
            if (!orderNumber.StartsWith("SC-", StringComparison.OrdinalIgnoreCase)
                || !int.TryParse(orderNumber[3..], out var sequence))
                throw new BusinessRuleException("Invalid order number.");

            var order = await _orderRepository.GetByOrderSequenceAsync(sequence);
            return order is null ? null : MapToDto(order);
        }
        public async Task FlagOrderExceptionAsync(Guid orderId, string notes)
        {
            var order = await _orderRepository.GetByIdAsync(orderId)
                ?? throw new KeyNotFoundException($"Order with ID {orderId} was not found.");

            order.FlagException(notes);

            await _notifications.AddAsync(new Notification(order.CustomerId,
                $"Issue with order {order.OrderNumber}", notes.Trim(), order.OrderId));

            await _orderRepository.Update(order);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task UpdateOrderStatusAsync(Guid orderId, OrderStatus newStatus)
        {
            var order = await _orderRepository.GetByIdAsync(orderId)
                ?? throw new KeyNotFoundException($"Order with ID {orderId} was not found.");

            if (order.FulfillmentMethod == Fulfillment_Method.Delivery)
            {
                if (newStatus == OrderStatus.Collected)
                {
                    var fee = await _paymentRepository.GetByOrderIdAndTypeAsync(orderId, PaymentType.DeliveryFee);
                    if (fee?.PaymentStatus != PaymentStatus.Paid)
                        throw new BusinessRuleException("The delivery fee must be paid before pickup.");
                }

                if (newStatus == OrderStatus.Completed)
                {
                    var pay = await _paymentRepository.GetByOrderIdAndTypeAsync(orderId, PaymentType.Orderpayment);
                    if (pay?.PaymentStatus != PaymentStatus.Paid)
                        throw new BusinessRuleException("The order must be paid before it is handed back.");
                }
            }

            order.UpdateStatus(newStatus);

            await _notifications.AddAsync(new Notification(order.CustomerId,
                $"Order {order.OrderNumber} update", $"Your order is now: {newStatus}.", order.OrderId));

            await _orderRepository.Update(order);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<IEnumerable<OrderDto>> GetCustomerOrdersAsync(Guid customerId)
        {
            var orders = await _orderRepository.GetByCustomerIdAsync(customerId);
            return orders.Select(MapToDto);
        }

        // Private helper to project Domain Entity -> DTO
        private static OrderDto MapToDto(Order order)
        {
            return new OrderDto(
                order.OrderId,
                order.CustomerId,
                order.OrderStatus.ToString(),
                order.TicketNumber,
                order.OrderNumber,
                order.IsFlaggedException,
                order.ExceptionNotes,
                order.GrandTotal,
                order.DeliveryFee,
                 order.ItemsTotal,
                 order.FulfillmentMethod.ToString(),
                order.OrderItems.Select(i => new OrderItemDto(i.ServiceId, i.Quantity, i.UnitPrice, i.Description)).ToList(),
                order.PickupFee,
                order.OrderDate,
                order.ReturnDate,
                order.PickupDate,
                order.DeliveryDate
            );
        }
    }
}
