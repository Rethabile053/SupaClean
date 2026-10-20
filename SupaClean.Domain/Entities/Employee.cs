using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Employee
    {
        public Guid EmployeeId { get; private set; }
        public Guid UserId {  get; private set; }
        public User User { get; private set; }
        public string Employee_Role { get; private set;  }

        private Employee() { }

        public Employee(
    Guid userId,
    string employeeRole)
        {
            if (userId == Guid.Empty)
                throw new BusinessRuleException(
                    "An employee must be associated with a user.");

            if (string.IsNullOrWhiteSpace(employeeRole))
                throw new BusinessRuleException(
                    "Employee role is required.");
            
            EmployeeId = Guid.NewGuid();
            UserId = userId;
            Employee_Role = employeeRole;
        }
    }
}
