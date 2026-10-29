using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SupaClean.Application.Contracts;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.Interfaces;
using SupaClean.Application.Services;
using SupaClean.Persistence.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructure(
     this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<AppDbContext>(o => o.UseNpgsql(connectionString));
            services.AddScoped<IUnitOfWork, UnitOfWork>();
            services.AddScoped<ICustomerRepository, CustomerRepository>();
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<IOrderRepository, OrderRepository>();
            services.AddScoped<IPayment, PaymentRepository>();
            services.AddScoped<IServiceRepository, ServiceRepository>();
            services.AddScoped<IDeliveryZoneRepository, DeliveryZoneRepository>();
            services.AddScoped<INotificationRepository, NotificationRepository>();

            return services;
        }
    }
}
