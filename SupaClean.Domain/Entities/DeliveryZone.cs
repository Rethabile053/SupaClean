using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class DeliveryZone
    {
        public Guid ZoneId { get; private set; }
        public string Name { get; private set; } = string.Empty;
        public decimal Fee { get; private set; }
        public bool IsActive { get; private set; }

        private DeliveryZone() { }

        public DeliveryZone(string name, decimal fee)
        {
            if (string.IsNullOrWhiteSpace(name))
                throw new BusinessRuleException("Zone name is required.");
            if (fee <= 0)
                throw new BusinessRuleException("Delivery fee must be greater than zero.");

            ZoneId = Guid.NewGuid();
            Name = name.Trim();
            Fee = fee;
            IsActive = true;
        }

        public void UpdateFee(decimal fee)
        {
            if (fee <= 0)
                throw new BusinessRuleException("Delivery fee must be greater than zero.");
            Fee = fee;
        }

        public void Activate() => IsActive = true;
        public void Deactivate() => IsActive = false;
    }
}
