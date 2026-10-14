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
        public Guid UserId { get;private set;  }
        public User User { get; private set; }
        public long ReferralId {  get; private set; }
        public  string City { get; private set; }
        public string Address { get; private set; }

        private Customer() { }
        public Customer(
    Guid userId,
    string city,
    string address)
        {
            if (userId == Guid.Empty)
                throw new BusinessRuleException(
                    "A customer must be associated with a user.");

            if (string.IsNullOrWhiteSpace(city))
                throw new BusinessRuleException(
                    "Customer city is required.");

            if (string.IsNullOrWhiteSpace(address))
                throw new BusinessRuleException(
                    "Customer address is required.");

            CustomerId = Guid.NewGuid();
            UserId = userId;
            City = city;
            Address = address;

        }


    }
}
