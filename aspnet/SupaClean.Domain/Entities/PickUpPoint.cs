using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class PickUpPoint
    {
        public Guid PickUpPointId { get; private set; }
        public string Name { get; private set; }
        public string Address{ get; private set; }
        public string ContactNumber { get; private set; }

        private PickUpPoint() { } 

        public PickUpPoint(string name, string address, string contactNumber)
        {
            if (string.IsNullOrWhiteSpace(name))
                throw new BusinessRuleException("Pickup point name is required.");

            if (string.IsNullOrWhiteSpace(address))
                throw new BusinessRuleException("Pickup point address is required.");

            if (string.IsNullOrWhiteSpace(contactNumber))
                throw new BusinessRuleException("Pickup point contact number is required.");

            PickUpPointId = Guid.NewGuid();
            Name = name;
            Address = address;
            ContactNumber = contactNumber;
         
        }

        public void UpdateDetails(string name, string address, string contactNumber)
        {
            if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(address) || string.IsNullOrWhiteSpace(contactNumber))
                throw new BusinessRuleException("Pickup point fields cannot be updated with empty values.");

            Name = name;
            Address = address;
            ContactNumber = contactNumber;
        }
    }
}
