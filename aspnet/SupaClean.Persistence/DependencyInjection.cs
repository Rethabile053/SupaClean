using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using SupaClean.Persistence.Push;
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
            // Push notifications: every saved Notification is also sent to the
            // customer's phones (see NotificationPushInterceptor).
            services.AddSingleton<NotificationPushInterceptor>();
            services.AddSingleton<IPushSender>(sp =>
            {
                var logger = sp.GetRequiredService<ILoggerFactory>().CreateLogger("Push");
                var keyPath = sp.GetRequiredService<IConfiguration>()["Firebase:CredentialsPath"];

                if (string.IsNullOrWhiteSpace(keyPath) || !File.Exists(keyPath))
                {
                    logger.LogWarning(
                        "Firebase:CredentialsPath is not set or the file is missing, so push notifications are off.");
                    return new NullPushSender(logger);
                }

                return new FirebasePushSender(keyPath, logger);
            });

            services.AddDbContext<AppDbContext>((sp, o) => o
                .UseNpgsql(connectionString)
                .AddInterceptors(sp.GetRequiredService<NotificationPushInterceptor>()));
            services.AddScoped<IDeviceTokenRepository, DeviceTokenRepository>();
            services.AddScoped<IDeviceService, DeviceService>();
            services.AddScoped<IPointsRepository, PointsRepository>();
            services.AddScoped<ILoyaltyService, LoyaltyService>();
            services.AddScoped<IUnitOfWork, UnitOfWork>();
            services.AddScoped<ICustomerRepository, CustomerRepository>();
            services.AddScoped<IOrderRepository, OrderRepository>();
            services.AddScoped<IPayment, PaymentRepository>();
            services.AddScoped<IServiceRepository, ServiceRepository>();
            services.AddScoped<IDeliveryZoneRepository, DeliveryZoneRepository>();
            services.AddScoped<INotificationRepository, NotificationRepository>();
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<IDeliveryRepository, DeliveryRepository>();
            services.AddScoped<IDriverRepository, DriverRepository>();
            services.AddScoped<ILocationRepository, LocationRepository>();

            return services;
        }
    }
}
