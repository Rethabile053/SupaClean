using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using SupaClean.Application.Contracts.Repositories;

namespace SupaClean.Persistence.Push
{
    // Sends push notifications through Firebase Cloud Messaging using the
    // project's service-account key.
    public class FirebasePushSender : IPushSender
    {
        // FCM accepts at most 500 devices per request.
        private const int BatchSize = 500;

        // Must match the channel the Flutter app creates and the Android manifest names.
        private const string AndroidChannel = "orders";

        private readonly FirebaseMessaging _messaging;
        private readonly ILogger _logger;

        public FirebasePushSender(string credentialsPath, ILogger logger)
        {
            _logger = logger;
            var app = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions
            {
                Credential = GoogleCredential.FromFile(credentialsPath)
            });
            _messaging = FirebaseMessaging.GetMessaging(app);
        }

        public async Task<IReadOnlyList<string>> SendAsync(
            IReadOnlyCollection<string> tokens, PushMessage message,
            CancellationToken cancellationToken = default)
        {
            var invalid = new List<string>();

            foreach (var batch in tokens.Chunk(BatchSize))
            {
                var multicast = new MulticastMessage
                {
                    Tokens = batch,
                    Notification = new Notification { Title = message.Title, Body = message.Body },
                    Data = message.OrderId is null
                        ? new Dictionary<string, string>()
                        : new Dictionary<string, string> { ["orderId"] = message.OrderId.Value.ToString() },
                    Android = new AndroidConfig
                    {
                        Priority = Priority.High,
                        Notification = new AndroidNotification { ChannelId = AndroidChannel }
                    }
                };

                var result = await _messaging.SendEachForMulticastAsync(multicast, cancellationToken);

                for (var i = 0; i < result.Responses.Count; i++)
                {
                    var error = result.Responses[i].Exception;
                    if (error is null) continue;

                    if (error.MessagingErrorCode is MessagingErrorCode.Unregistered
                        or MessagingErrorCode.InvalidArgument)
                        invalid.Add(batch[i]);
                    else
                        _logger.LogWarning("Push failed for one device: {Error}", error.Message);
                }
            }

            return invalid;
        }
    }
}
