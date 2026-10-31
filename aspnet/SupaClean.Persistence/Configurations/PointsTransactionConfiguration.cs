using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SupaClean.Domain.Entities;

namespace SupaClean.Persistence.Configurations
{
    public class PointsTransactionConfiguration : IEntityTypeConfiguration<PointsTransaction>
    {
        public void Configure(EntityTypeBuilder<PointsTransaction> b)
        {
            b.HasKey(t => t.PointsTransactionId);
            b.Property(t => t.Kind).HasConversion<string>().HasMaxLength(20);
            b.Property(t => t.Description).IsRequired().HasMaxLength(PointsTransaction.MaxDescriptionLength);
            b.HasIndex(t => t.CustomerId);
            b.HasIndex(t => new { t.OrderId, t.Kind });
            b.HasOne<Customer>().WithMany().HasForeignKey(t => t.CustomerId).OnDelete(DeleteBehavior.Cascade);
            b.HasOne<Order>().WithMany().HasForeignKey(t => t.OrderId).OnDelete(DeleteBehavior.SetNull);
        }
    }
}
