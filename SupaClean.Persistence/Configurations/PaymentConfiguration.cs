using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Configurations
{
    public class PaymentConfiguration : IEntityTypeConfiguration<Payment>
    {

        public void Configure(EntityTypeBuilder<Payment> b)
        {
            b.HasKey(p => p.PaymentId);
            b.HasOne(p => p.Order).WithMany().HasForeignKey(p => p.OrderId)
             .OnDelete(DeleteBehavior.Restrict);
            b.HasIndex(p => new { p.OrderId, p.PaymentType });

            b.Property(p => p.PaymentType).HasConversion<string>().HasMaxLength(20);
            b.Property(p => p.PaymentMethod).HasConversion<string>().HasMaxLength(20);
            b.Property(p => p.PaymentStatus).HasConversion<string>().HasMaxLength(20);
            b.Property(p => p.VerificationStatus).HasConversion<string>().HasMaxLength(20);
            b.Property(p => p.Amount).HasPrecision(10, 2);
            b.Property(p => p.BankReference).HasMaxLength(100);
            b.Property(p => p.ProofOfPayment).HasMaxLength(500);
            b.Property(p => p.RejectionReason).HasMaxLength(500);
        }
    }
}
