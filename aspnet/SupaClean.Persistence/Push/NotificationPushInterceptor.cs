using System.Runtime.CompilerServices;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Domain.Entities;

namespace SupaClean.Persistence.Push
{
    // Whenever a Notification row is saved (order status change, payment,
    // cancellation, ...), also push it to the customer's phones. One place
    // covers every part of the system that creates notifications, in both the
    // Web API and the admin site. A failed push never fails the save.
    public sealed class NotificationPushInterceptor : SaveChangesInterceptor
    {
        private sealed record Pending(Guid CustomerId, string Title, string Message, Guid? OrderId);

        private readonly IServiceScopeFactory _scopes;
        private readonly ILogger<NotificationPushInterceptor> _logger;
        private readonly ConditionalWeakTable<DbContext, List<Pending>> _pending = new();

        public NotificationPushInterceptor(
            IServiceScopeFactory scopes, ILogger<NotificationPushInterceptor> logger)
        {
            _scopes = scopes;
            _logger = logger;
        }

        public override InterceptionResult<int> SavingChanges(
            DbContextEventData eventData, InterceptionResult<int> result)
        {
            Remember(eventData.Context);
            return result;
        }

        public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
            DbContextEventData eventData, InterceptionResult<int> result,
            CancellationToken cancellationToken = default)
        {
            Remember(eventData.Context);
            return ValueTask.FromResult(result);
        }

        public override int SavedChanges(SaveChangesCompletedEventData eventData, int result)
        {
            Send(eventData.Context);
            return result;
        }

        public override ValueTask<int> SavedChangesAsync(
            SaveChangesCompletedEventData eventData, int result,
            CancellationToken cancellationToken = default)
        {
            Send(eventData.Context);
            return ValueTask.FromResult(result);
        }

        public override void SaveChangesFailed(DbContextErrorEventData eventData)
            => Forget(eventData.Context);

        public override Task SaveChangesFailedAsync(
            DbContextErrorEventData eventData, CancellationToken cancellationToken = default)
        {
            Forget(eventData.Context);
            return Task.CompletedTask;
        }

        private void Remember(DbContext? context)
        {
            if (context is null) return;

            var added = context.ChangeTracker.Entries<Notification>()
                .Where(e => e.State == EntityState.Added)
                .Select(e => new Pending(
                    e.Entity.CustomerId, e.Entity.Title, e.Entity.Message, e.Entity.OrderId))
                .ToList();

            _pending.Remove(context);
            if (added.Count > 0) _pending.Add(context, added);
        }

        private void Forget(DbContext? context)
        {
            if (context is not null) _pending.Remove(context);
        }

        private void Send(DbContext? context)
        {
            if (context is null || !_pending.TryGetValue(context, out var list)) return;
            _pending.Remove(context);

            // Don't make the admin wait for Firebase.
            _ = Task.Run(() => DeliverAsync(list));
        }

        private async Task DeliverAsync(List<Pending> list)
        {
            try
            {
                using var scope = _scopes.CreateScope();
                var devices = scope.ServiceProvider.GetRequiredService<IDeviceTokenRepository>();
                var sender = scope.ServiceProvider.GetRequiredService<IPushSender>();

                foreach (var item in list)
                {
                    var tokens = await devices.GetTokensForCustomerAsync(item.CustomerId);
                    if (tokens.Count == 0) continue;

                    var invalid = await sender.SendAsync(
                        tokens, new PushMessage(item.Title, item.Message, item.OrderId));

                    if (invalid.Count > 0)
                        await devices.RemoveByTokensAsync(invalid);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not push a notification.");
            }
        }
    }
}
