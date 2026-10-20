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
    public class DeliveryZoneConfiguration : IEntityTypeConfiguration<DeliveryZone>
    {
        public void Configure(EntityTypeBuilder<DeliveryZone> b)
        {
            b.HasKey(z => z.ZoneId);
            b.Property(z => z.Name).HasMaxLength(100).IsRequired();
            b.HasIndex(z => z.Name).IsUnique();
            b.Property(z => z.Fee).HasPrecision(10, 2);

            // PLACEHOLDER fees: replace with SupaClean's real prices before the demo
            b.HasData(
                new { ZoneId = Guid.Parse("11111111-1111-1111-1111-111111111111"), Name = "Bloemfontein", Fee = 60m, IsActive = true },
                new { ZoneId = Guid.Parse("22222222-2222-2222-2222-222222222222"), Name = "Botshabelo", Fee = 120m, IsActive = true },
                new { ZoneId = Guid.Parse("33333333-3333-3333-3333-333333333333"), Name = "Thaba Nchu", Fee = 150m, IsActive = true });
        }
    }
}
