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
    List<OrderItemDto> Items,
    decimal PickupFee = 0,
    DateTime? OrderDate = null,
    DateTime? ReturnDate = null,
    DateTime? PickupDate = null,
    DateTime? DeliveryDate = null,
    List<OrderStatusChangeDto>? StatusHistory = null,
    string? PickupMethod = null,      // how the laundry gets to us, as the customer chose it in the app
    string? ReturnMethod = null,      // how it gets back to the customer
    decimal PointsDiscount = 0        // rand taken off by using points (already out of GrandTotal)
    );
}
