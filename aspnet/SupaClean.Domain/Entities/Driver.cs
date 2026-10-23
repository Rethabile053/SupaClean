using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Driver
    {
        public Guid DriverId { get; private set; }
        public Guid EmployeeId { get; private set; }
        public Employee Employee { get; private set; }
        public string Email { get; private set; }
        public string Password { get; private set; }

        public string LicenseNumber { get;private set;  }

        public Driver(
     Guid employeeId,string password, string email
     string licenseNumber)
        {
            if (password == string.Empty)
                throw new BusinessRuleException(
                    "A driver must be associated with an employee.");

            if (string.IsNullOrWhiteSpace(licenseNumber))
                throw new BusinessRuleException(
                    "A driver must have a license number.");

            DriverId = Guid.NewGuid();
            EmployeeId = employeeId;
            LicenseNumber = licenseNumber;
            Email = email,
            Password = password
        }

    }
}
