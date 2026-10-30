using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Enums
{
    public enum Role
    {
        Customer,
        Driver ,
        Admin,
        // A driver who has created an account and is waiting for an admin to approve it.
        // They cannot sign in to the driver portal or be given orders until approved.
        PendingDriver
    }
}
