using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.DTOs
{
    public record CreateCustomerDto
    (
    string FirstName,
    string LastName,
    string Email,
    string PasswordHash,
    string PhoneNumber,
    string City,
    string Address
     );
}
