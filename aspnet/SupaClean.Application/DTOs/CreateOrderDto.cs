using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record CreateOrderDTO
    (
        Guid CustomerId,
    string? SpecialInstructions,
    Guid? DeliveryZoneId,
    List<CreateOrderItemDto> Items,
      string FulfillmentMethod
        );
}
