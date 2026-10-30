using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SupaClean.Domain.Entities;

namespace SupaClean.Persistence.Configurations
{
    public class DeviceTokenConfiguration : IEntityTypeConfiguration<DeviceToken>
    {
        public void Configure(EntityTypeBuilder<DeviceToken> b)
        {
            b.HasKey(d => d.DeviceTokenId);
            b.Property(d => d.Token).IsRequired().HasMaxLength(DeviceToken.MaxTokenLength);
            b.Property(d => d.Platform).IsRequired().HasMaxLength(DeviceToken.MaxPlatformLength);
            b.HasIndex(d => d.Token).IsUnique();
            b.HasIndex(d => d.CustomerId);
            b.HasOne<Customer>().WithMany().HasForeignKey(d => d.CustomerId).OnDelete(DeleteBehavior.Cascade);
        }
    }
}
