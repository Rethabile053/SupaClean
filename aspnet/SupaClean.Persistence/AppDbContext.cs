using Microsoft.EntityFrameworkCore;
using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence
{
    public class AppDbContext:DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users => Set<User>();
        public DbSet<Customer> Customers => Set<Customer>();
        public DbSet<Admin> Admins => Set<Admin>();
        public DbSet<Employee> Employees => Set<Employee>();
        public DbSet<Driver> Drivers => Set<Driver>();
        public DbSet<Order> Orders => Set<Order>();
        public DbSet<OrderItem> OrderItems => Set<OrderItem>();
        public DbSet<OrderStatusChange> OrderStatusChanges => Set<OrderStatusChange>();
        public DbSet<Payment> Payments => Set<Payment>();
        public DbSet<Delivery> Deliveries => Set<Delivery>();
        public DbSet<Service> Services => Set<Service>();
        public DbSet<PickUpPoint> PickUpPoints => Set<PickUpPoint>();
        public DbSet<Location> Locations => Set<Location>();
        public DbSet<Notification> Notifications => Set<Notification>();
        public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
        public DbSet<PointsTransaction> PointsTransactions => Set<PointsTransaction>();
        
        public DbSet<DeliveryZone> DeliveryZones => Set<DeliveryZone>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

           
            modelBuilder.HasDefaultSchema("app");
            modelBuilder.Ignore<Banking_Details>();
            modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
        }
    }
}
