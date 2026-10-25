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
    string FirstName,
    string Email,    
    string PhoneNumber, 
    string City,
    string LastName, 
    string ReferralCode,
    string Address
       );
}
