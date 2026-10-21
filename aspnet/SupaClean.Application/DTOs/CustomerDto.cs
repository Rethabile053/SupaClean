using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record CustomerDto
    (
    Guid CustomerId,
    Guid UserId,
    string FullName,
    string Email,    
    string PhoneNumber, 
    string City,    
    string Address
       );
}
