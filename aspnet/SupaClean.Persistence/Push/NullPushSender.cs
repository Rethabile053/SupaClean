using Microsoft.Extensions.Logging;
using SupaClean.Application.Contracts.Repositories;

namespace SupaClean.Persistence.Push
{
    // Used when no Firebase key is configured: notifications are still saved
    // for the app's Notification Center, but nothing is pushed to phones.
    public class NullPushSender : IPushSender
    {
        private readonly ILogger _logger;
        public NullPushSender(ILogger logger) => _logger = logger;

        public Task<IReadOnlyList<string>> SendAsync(
            IReadOnlyCollection<string> tokens, PushMessage message,
            CancellationToken cancellationToken = default)
        {
            _logger.LogWarning(
                "Push not sent to {Count} device(s): set Firebase:CredentialsPath to the service-account key file.",
                tokens.Count);
            return Task.FromResult<IReadOnlyList<string>>(Array.Empty<string>());
        }
    }
}
