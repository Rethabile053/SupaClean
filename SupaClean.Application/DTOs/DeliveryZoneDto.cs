using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record DeliveryZoneDto(
        Guid ZoneId, 
        string Name,
        decimal Fee,
        bool IsActive
        );
}
