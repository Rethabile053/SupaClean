using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SupaClean.Domain.Entities;

namespace SupaClean.Persistence.Configurations
{
    public class OrderStatusChangeConfiguration : IEntityTypeConfiguration<OrderStatusChange>
    {
        public void Configure(EntityTypeBuilder<OrderStatusChange> b)
        {
            b.HasKey(c => c.Id);
            b.Property(c => c.Id).UseIdentityByDefaultColumn();
            b.Property(c => c.Status).HasConversion<string>().HasMaxLength(30);
            b.HasIndex(c => c.OrderId);
        }
    }
}
