using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public  class User
    {
        public Guid UserId { get; private set; }
        public string FirstName { get; private set; }
        public string LastName { get; private set; }
        public string Email { get; private set; }

        public string PasswordHash { get; private set; }
        public string ? PhoneNumber { get; private set;  }
        public Role Role { get; private set; }

        private User() { } 

        public User(
           Guid userid, string firstName, string lastName,
            string email, string phoneNumber, Role role = Role.Customer)
        {
            if (userid == Guid.Empty)
                throw new BusinessRuleException("User ID must match Supabase Auth identity.");

            if (string.IsNullOrWhiteSpace(firstName))
                throw new BusinessRuleException("First name is required.");

            if (string.IsNullOrWhiteSpace(lastName))
                throw new BusinessRuleException("Last name is required.");

            if (string.IsNullOrWhiteSpace(email) || !email.Contains("@"))
                throw new BusinessRuleException("A valid email address is required.");

            UserId = userid;
            FirstName = firstName;
            LastName = lastName;
            Email = email.ToLowerInvariant();
            PhoneNumber = phoneNumber;
            Role = role;
        }

        public void UpdateContactInfo(string firstName, string lastName, string phoneNumber)
        {
            if (string.IsNullOrWhiteSpace(firstName) || string.IsNullOrWhiteSpace(lastName))
                throw new BusinessRuleException("Name fields cannot be empty.");

            FirstName = firstName;
            LastName = lastName;
            PhoneNumber = phoneNumber;
        }
    }

}
