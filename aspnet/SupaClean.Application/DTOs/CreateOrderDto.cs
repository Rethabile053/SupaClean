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
      string FulfillmentMethod,
    bool HomePickup = false,      // true: we collect from the customer's address (adds the pickup fee)
    DateTime? PickupDate = null,      // requested pickup time (UTC)
    DateTime? DeliveryDate = null     // requested delivery time (UTC)
        );
}
