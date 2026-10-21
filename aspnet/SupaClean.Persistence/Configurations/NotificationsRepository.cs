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
    public class NotificationConfiguration : IEntityTypeConfiguration<Notification>
    {
        public void Configure(EntityTypeBuilder<Notification> b)
        {
            b.HasKey(n => n.NotificationId);
            b.HasOne(n => n.Customer).WithMany().HasForeignKey(n => n.CustomerId)
             .OnDelete(DeleteBehavior.Cascade);
            b.Property(n => n.Title).HasMaxLength(150).IsRequired();
            b.Property(n => n.Message).HasMaxLength(1000).IsRequired();
            b.HasIndex(n => new { n.CustomerId, n.IsRead, n.SentAt });
        }
    }
}
