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
        Task<Guid> CreateOrderAsync(CreateOrderDTO dto);
        Task LinkPhysicalTicketAsync(Guid orderId, string ticketNumber);
        Task UpdateOrderStatusAsync(Guid orderId, OrderStatus newStatus);
        Task FlagOrderExceptionAsync(Guid orderId, string notes);
        Task<OrderDto?> GetOrderByIdAsync(Guid orderId);
        Task<IEnumerable<OrderDto>> GetCustomerOrdersAsync(Guid customerId);
    }
}
