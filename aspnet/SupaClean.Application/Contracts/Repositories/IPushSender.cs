namespace SupaClean.Application.Contracts.Repositories
{
    public record PushMessage(string Title, string Body, Guid? OrderId);

    // Delivers a push notification to phones through Firebase Cloud Messaging.
    public interface IPushSender
    {
        // Returns the tokens that no longer work, so they can be forgotten.
        Task<IReadOnlyList<string>> SendAsync(
            IReadOnlyCollection<string> tokens,
            PushMessage message,
            CancellationToken cancellationToken = default);
    }
}
