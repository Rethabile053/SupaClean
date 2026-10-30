using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record CreateServiceDto
  (
        string Name,
    string Description,
    int TurnaroundDays,
    decimal BasePrice,
    string? Category = null
        );
}
