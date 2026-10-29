using SupaClean.Domain.Exceptions;

namespace SupaClean.Domain.Entities
{
    // A phone (or browser) that can receive push notifications for a customer.
    public class DeviceToken
    {
        public const int MaxTokenLength = 1024;
        public const int MaxPlatformLength = 20;

        public Guid DeviceTokenId { get; private set; }
        public Guid CustomerId { get; private set; }
        public string Token { get; private set; } = string.Empty;
        public string Platform { get; private set; } = string.Empty;   // android, ios, web
        public DateTime CreatedAt { get; private set; }
        public DateTime UpdatedAt { get; private set; }

        private DeviceToken() { }

        public DeviceToken(Guid customerId, string token, string? platform)
        {
            DeviceTokenId = Guid.NewGuid();
            CreatedAt = DateTime.UtcNow;
            Token = CleanToken(token);
            AssignTo(customerId, platform);
        }

        // The same phone can be used by a different customer after a sign-out
        // and sign-in, so the token moves to whoever is using it now.
        public void AssignTo(Guid customerId, string? platform)
        {
            if (customerId == Guid.Empty)
                throw new BusinessRuleException("A device must belong to a customer.");

            CustomerId = customerId;
            Platform = CleanPlatform(platform);
            UpdatedAt = DateTime.UtcNow;
        }

        public static string CleanToken(string? token)
        {
            var value = token?.Trim() ?? string.Empty;
            if (value.Length == 0)
                throw new BusinessRuleException("A device token is required.");
            if (value.Length > MaxTokenLength)
                throw new BusinessRuleException("The device token is too long.");
            return value;
        }

        private static string CleanPlatform(string? platform)
        {
            var value = platform?.Trim().ToLowerInvariant() ?? string.Empty;
            if (value.Length == 0) return "unknown";
            return value.Length > MaxPlatformLength ? value[..MaxPlatformLength] : value;
        }
    }
}
