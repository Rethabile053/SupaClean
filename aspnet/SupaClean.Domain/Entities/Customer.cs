using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Customer
    {
        public Guid CustomerId { get; private set; }
        public Guid UserId { get; private set; }
        public User User { get; private set; } = null!;
        public string ReferralCode { get; private set; } = string.Empty;   // what a customer shares
        public Guid? ReferredByCustomerId { get; private set; }            // null if nobody referred them
        public string City { get; private set; } = string.Empty;
        public string Address { get; private set; } = string.Empty;

        private Customer() { }

        public Customer(User user, string city, string address)
        {
            if (user is null || user.UserId == Guid.Empty)
                throw new BusinessRuleException("A customer must be associated with a user.");
            if (string.IsNullOrWhiteSpace(city))
                throw new BusinessRuleException("Customer city is required.");
            if (string.IsNullOrWhiteSpace(address))
                throw new BusinessRuleException("Customer address is required.");

            CustomerId = Guid.NewGuid();
            ReferralCode = Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
            User = user;
            UserId = user.UserId;
            City = city.Trim();
            Address = address.Trim();
        }

        public void UpdateDetails(string city, string address)
        {
            if (string.IsNullOrWhiteSpace(city))
                throw new BusinessRuleException("City is required.");
            if (string.IsNullOrWhiteSpace(address))
                throw new BusinessRuleException("Address is required.");

            City = city.Trim();
            Address = address.Trim();
        }
        public void SetReferrer(Guid referrerCustomerId)
        {
            if (ReferredByCustomerId is not null)
                throw new BusinessRuleException("A referrer has already been set.");
            if (referrerCustomerId == CustomerId)
                throw new BusinessRuleException("You cannot refer yourself.");

            ReferredByCustomerId = referrerCustomerId;
        }
    }
}
