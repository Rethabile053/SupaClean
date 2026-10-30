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
        

        private Admin() { }
        public Admin(Guid employeeId,string email)
        {
            if (employeeId == Guid.Empty)
                throw new BusinessRuleException(
                    "An admin must be associated with an employee.");


            EmployeeId = employeeId;

            Email = email;
       
     
            AdminId = Guid.NewGuid();
           
        }
    }
}
