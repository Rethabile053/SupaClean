using Microsoft.IdentityModel.Tokens;

namespace SupaClean.WebApi.Security
{
    public static class SupabaseKeys
    {
        private static JsonWebKeySet? _set;
        private static DateTime _fetchedAt;

        public static IEnumerable<SecurityKey> Get(string jwksUrl)
        {
            if (_set is null || DateTime.UtcNow - _fetchedAt > TimeSpan.FromHours(1))
            {
                using var http = new HttpClient();
                _set = new JsonWebKeySet(http.GetStringAsync(jwksUrl).GetAwaiter().GetResult());
                _fetchedAt = DateTime.UtcNow;
            }
            return _set.GetSigningKeys();
        }
    }
}
