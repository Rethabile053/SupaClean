using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Admin
    {
        public Guid AdminId { get; private set; }
        public Guid EmployeeId { get; private set; }
        public string Email { get; private set; }
        public string Password { get; private set; }

        private Admin() { }
        public Admin(Guid employeeId)
        {
            if (employeeId == Guid.Empty)
                throw new BusinessRuleException(
                    "An admin must be associated with an employee.");


            EmployeeId = employeeId;
            //Email = email;
            //Password = password;
            AdminId = Guid.NewGuid();
           
        }
    }
}
