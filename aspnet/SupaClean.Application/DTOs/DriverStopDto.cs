using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record DriverStopDto(
     Guid OrderId,
     string OrderNumber,
     string StopType,            // "Pickup" or "Delivery"
     string CustomerName,
     string? CustomerPhone,
     string City,
     string Address,
     string? SpecialInstructions,
     string? PaymentMethod,      // for deliveries: "CashOnDelivery", "Eft" or "NotSelected"
     decimal AmountDue);         // what the driver must collect in cash, 0 if nothing


}
