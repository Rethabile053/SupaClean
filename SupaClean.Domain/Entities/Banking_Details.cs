using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Domain.Entities
{
    public class Banking_Details
    {
        public Guid BankDetailsId { get; private set; }
        public string AccountNumber { get; private set; }
        public string BankName { get; private set; }
        public string BankReference { get; private set; }

        private Banking_Details() { }

        public Banking_Details(
    string accountNumber,
    string bankName,
    string bankReference)
        {
            if (string.IsNullOrWhiteSpace(accountNumber))
                throw new BusinessRuleException(
                    "Account number is required.");

            if (string.IsNullOrWhiteSpace(bankName))
                throw new BusinessRuleException(
                    "Bank name is required.");

            if (string.IsNullOrWhiteSpace(bankReference))
                throw new BusinessRuleException(
                    "Bank reference is required.");

            BankDetailsId = Guid.NewGuid();
            AccountNumber = accountNumber;
            BankName = bankName;
            BankReference = bankReference;
        }
    }
}
