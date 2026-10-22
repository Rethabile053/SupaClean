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
    public class UserConfiguration : IEntityTypeConfiguration<User>
    {
        public void Configure(EntityTypeBuilder<User> b)
        {
            b.HasKey(u => u.UserId);
            b.Property(u => u.FirstName).HasMaxLength(100).IsRequired();
            b.Property(u => u.LastName).HasMaxLength(100).IsRequired();
            b.Property(u => u.Email).HasMaxLength(200).IsRequired();
            b.HasIndex(u => u.Email).IsUnique();
            b.Property(u => u.PhoneNumber).HasMaxLength(30);
            b.Property(u => u.Role).HasConversion<string>().HasMaxLength(20);
        }
    }
}
