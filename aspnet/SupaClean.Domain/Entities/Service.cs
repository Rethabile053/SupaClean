using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Service
    {
        public Guid ServiceId { get; private set; }
        public string ServiceName { get; private set; } = string.Empty;
        public decimal Price { get; private set; }
        public int TurnaroundDays { get; private set; }
        public bool IsActive { get; private set; }
        public string? ServiceDescription { get; private set; }

        private Service() { }

        public Service(string serviceName, decimal price, int turnaroundDays,
                       string? serviceDescription = null)
        {
            if (string.IsNullOrWhiteSpace(serviceName))
                throw new BusinessRuleException("Service name is required.");
            if (price < 0)
                throw new BusinessRuleException("Service price cannot be negative.");
            if (turnaroundDays < 1)
                throw new BusinessRuleException("Turnaround must be at least 1 day.");

            ServiceId = Guid.NewGuid();
            ServiceName = serviceName.Trim();
            Price = price;
            TurnaroundDays = turnaroundDays;
            ServiceDescription = serviceDescription;
            IsActive = true;
        }

        public void UpdatePrice(decimal newPrice)
        {
            if (newPrice < 0)
                throw new BusinessRuleException("Service price cannot be negative.");
            Price = newPrice;
        }

        public void UpdateTurnaround(int days)
        {
            if (days < 1)
                throw new BusinessRuleException("Turnaround must be at least 1 day.");
            TurnaroundDays = days;
        }

        public void Activate() => IsActive = true;
        public void Deactivate() => IsActive = false;
    }
}
