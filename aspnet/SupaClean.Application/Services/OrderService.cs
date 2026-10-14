using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
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
        private readonly IUnitOfWork _unitOfWork;

        public OrderService(IOrderRepository orderRepository, IUnitOfWork unitOfWork)
        {
            _orderRepository = orderRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Guid> CreateOrderAsync(CreateOrderDTO dto)
        {
            //  Instantiate the Rich Domain Entity 
            var order = new Order(dto.CustomerId, dto.SpecialInstructions);

            //  Add line items using the Domain Method on the Aggregate Root
            foreach (var item in dto.Items)
            {
                // order.AddOrderItem internally recalculates total amount and validates pricing/quantity
                order.AddOrderItem(item.ServiceId, item.Quantity, item.UnitPrice, item.Description);
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

        public async Task UpdateOrderStatusAsync(Guid orderId, OrderStatus newStatus)
        {
            var order = await _orderRepository.GetByIdAsync(orderId)
                ?? throw new KeyNotFoundException($"Order with ID {orderId} was not found.");

            order.UpdateStatus(newStatus);

            _orderRepository.Update(order);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task FlagOrderExceptionAsync(Guid orderId, string notes)
        {
            var order = await _orderRepository.GetByIdAsync(orderId)
                ?? throw new KeyNotFoundException($"Order with ID {orderId} was not found.");

            // Domain method validates that notes aren't empty and sets IsFlaggedException = true
            order.FlagException(notes);

            _orderRepository.Update(order);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<OrderDto?> GetOrderByIdAsync(Guid orderId)
        {
            var order = await _orderRepository.GetByIdAsync(orderId);
            if (order == null) return null;

            return MapToDto(order);
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
                order.TotalAmount,
                order.TicketNumber,
                order.IsFlaggedException,
                order.ExceptionNotes,
                order.OrderItems.Select(i => new OrderItemDto(i.ServiceId, i.Quantity, i.UnitPrice, i.Description)).ToList()
            );
        }
    }
}
