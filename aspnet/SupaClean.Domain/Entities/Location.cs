using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Location
    {
        public Guid LocationId { get; private set; }
        public string AddressLine1 { get; private set; }
        public string ? AddressLine2 { get; private set; } 
        public string AddressCity { get; private set; }

        private Location() { }
        public Location(
    string addressLine1,
    string addressCity)
        {
            if (string.IsNullOrWhiteSpace(addressLine1))
                throw new BusinessRuleException(
                    "Address line 1 is required.");

            if (string.IsNullOrWhiteSpace(addressCity))
                throw new BusinessRuleException(
                    "City is required.");

            LocationId = Guid.NewGuid();
            AddressLine1 = addressLine1;
            AddressCity = addressCity;
        }
    }
}
