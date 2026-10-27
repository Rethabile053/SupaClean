using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;
using SupaClean.Domain.Entities;


namespace SupaClean.Application.DTOs
{
    public record OrderDto
    (
      Guid OrderId,
     Guid CustomerId,
    string OrderStatus,
    string? TicketNumber,
   string OrderNumber ,
    bool IsFlaggedException,
    string? ExceptionNotes,
    decimal GrandTotal,
    decimal DeliveryFee,
     decimal ItemsTotal,
     //added the fulfillmentMethod property,
     string FulfillmentMethod,
    List<OrderItemDto> Items
    );
}
