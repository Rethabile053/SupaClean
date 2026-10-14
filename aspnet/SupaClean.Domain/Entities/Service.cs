using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public  class Service
    {
        public Guid ServiceId { get; private set; }
        public string ServiceName { get; private set; }

        public decimal Price { get; private set; }
        public string? ServiceDescription { get; private set; }

        private Service() { } 

        public Service(string serviceName, decimal price, string? serviceDescription = null)
        {
            if (string.IsNullOrWhiteSpace(serviceName))
                throw new BusinessRuleException("Service name is required.");

            if (price < 0)
                throw new BusinessRuleException("Service price cannot be negative.");

            ServiceId = Guid.NewGuid();
            ServiceName = serviceName;
            Price = price;
            ServiceDescription = serviceDescription;
           
        }

        public void UpdatePrice(decimal newPrice)
        {
            if (newPrice < 0)
                throw new BusinessRuleException("Service price cannot be negative.");

            Price = newPrice;
        }
    }
}
