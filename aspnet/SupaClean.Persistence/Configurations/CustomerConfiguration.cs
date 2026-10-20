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
    public  class CustomerConfiguration: IEntityTypeConfiguration<Customer>
    {

        public void Configure(EntityTypeBuilder<Customer> b)
        {
            b.HasKey(c => c.CustomerId);
            b.HasOne(c => c.User).WithOne().HasForeignKey<Customer>(c => c.UserId)
             .OnDelete(DeleteBehavior.Restrict);
            b.HasIndex(c => c.UserId).IsUnique();
            b.HasIndex(c => c.ReferralCode).IsUnique();
            b.HasIndex(c => c.ReferredByCustomerId);
            b.Property(c => c.City).HasMaxLength(100).IsRequired();
            b.Property(c => c.Address).HasMaxLength(300).IsRequired();
            b.Property(c => c.ReferralCode).HasMaxLength(12).IsRequired();
        }
    }
}
