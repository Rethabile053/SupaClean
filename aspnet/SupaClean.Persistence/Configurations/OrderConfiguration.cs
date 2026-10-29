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
    public  class OrderConfiguration: IEntityTypeConfiguration<Order>
    {
        public void Configure(EntityTypeBuilder<Order> b)
        {
            b.HasKey(o => o.OrderId);
            b.HasOne(o => o.Customer).WithMany().HasForeignKey(o => o.CustomerId)
             .OnDelete(DeleteBehavior.Restrict);
            b.Property(o => o.OrderSequence).UseIdentityByDefaultColumn()
            .HasIdentityOptions(startValue: 1001);
            b.HasIndex(o => o.OrderSequence).IsUnique();
            b.Ignore(o => o.OrderNumber);

            b.Property(o => o.OrderStatus).HasConversion<string>().HasMaxLength(30);
            b.Property(o => o.FulfillmentMethod).HasConversion<string>().HasMaxLength(30);
            b.Property(o => o.ItemsTotal).HasPrecision(10, 2);
            b.Property(o => o.DeliveryFee).HasPrecision(10, 2);
            b.Property(o => o.PickupFee).HasPrecision(10, 2);
            b.Ignore(o => o.GrandTotal);                 // computed, not stored

            b.Property(o => o.TicketNumber).HasMaxLength(50);
            b.HasIndex(o => o.TicketNumber).IsUnique();  // several NULLs are allowed in Postgres
            b.Property(o => o.SpecialInstructions).HasMaxLength(500);
            b.Property(o => o.ExceptionNotes).HasMaxLength(500);


            b.HasMany(o => o.OrderItems)
           .WithOne(i => i.Order)
           .HasForeignKey(i => i.OrderId)
           .OnDelete(DeleteBehavior.Cascade);
            b.Navigation(o => o.OrderItems).HasField("_orderItems")
             .UsePropertyAccessMode(PropertyAccessMode.Field);
            b.HasMany(o => o.StatusHistory).WithOne().HasForeignKey(c => c.OrderId)
             .OnDelete(DeleteBehavior.Cascade);
            b.Navigation(o => o.StatusHistory).HasField("_statusHistory")
             .UsePropertyAccessMode(PropertyAccessMode.Field);
            b.HasOne<DeliveryZone>().WithMany().HasForeignKey(o => o.DeliveryZoneId)
           .OnDelete(DeleteBehavior.Restrict);

        }
    }
}
