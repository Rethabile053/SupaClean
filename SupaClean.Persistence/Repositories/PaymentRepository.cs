using SupaClean.Application.Contracts.Repositories;
using Microsoft.EntityFrameworkCore;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Repositories
{
    public class PaymentRepository : Repository<Payment>, IPayment
    {
        public PaymentRepository(AppDbContext db) : base(db) { }

        public async Task<IEnumerable<Payment>> GetUnverifiedPaymentsAsync()
            => await _set.Where(p => p.PaymentMethod == PaymentMethod.EFT
                                  && p.VerificationStatus == VerificationStatus.Pending)
                         .OrderBy(p => p.PaymentDate)
                         .ToListAsync();

        public async Task<Payment?> GetByOrderIdAndTypeAsync(Guid orderId, PaymentType type)
            => await _set.Where(p => p.OrderId == orderId && p.PaymentType == type)
                         .OrderByDescending(p => p.PaymentDate)
                         .FirstOrDefaultAsync();   // latest one, in case an earlier one was declined

        public async Task<IEnumerable<Payment>> GetByOrderIdAsync(Guid orderId)
            => await _set.Where(p => p.OrderId == orderId)
                         .OrderBy(p => p.PaymentDate)
                         .ToListAsync();
    }
}
