using SupaClean.Application.DTOs;
using SupaClean.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Interfaces
{
    public interface IOrderService
    {
        Task<Guid> CreateOrderAsync(Guid customerId,CreateOrderDTO dto);
        Task<IEnumerable<OrderDto>> GetAllOrdersAsync(); 
        // Only the orders this driver has been given a job for (collecting or delivering).
        Task<IEnumerable<OrderDto>> GetOrdersForDriverAsync(Guid driverUserId);
        Task<OrderDto?> GetOrderByNumberAsync(string orderNumber);
        Task LinkPhysicalTicketAsync(Guid orderId, string ticketNumber);
        Task UpdateOrderStatusAsync(Guid orderId, OrderStatus newStatus);
        Task FlagOrderExceptionAsync(Guid orderId, string notes);
        Task CancelOrderAsync(Guid orderId, Guid customerId);
        Task<OrderDto?> GetOrderByIdAsync(Guid orderId);
        Task<IEnumerable<OrderDto>> GetCustomerOrdersAsync(Guid customerId);
    }
}
