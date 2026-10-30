using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record ServiceDto
    (
       Guid ServiceId, 
       string ServiceName,
       string? ServiceDescription,
       decimal Price, 
       int TurnaroundDays,
       bool IsActive,
       string? Category = null);
    
   
}
