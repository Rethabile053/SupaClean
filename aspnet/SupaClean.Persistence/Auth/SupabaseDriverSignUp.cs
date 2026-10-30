using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;

namespace SupaClean.Persistence.Auth
{
    // Public sign-up through Supabase Auth. It uses the project's public (anon) key, the
    // same one the mobile app signs customers up with, so no master key is involved.
    public class SupabaseDriverSignUp : IDriverSignUp
    {
        private readonly HttpClient _http;
        private readonly IConfiguration _config;

        public SupabaseDriverSignUp(HttpClient http, IConfiguration config)
        {
            _http = http;
            _config = config;
        }

        public async Task<SignUpResult> SignUpAsync(string email, string password, string fullName,
            string? phoneNumber, CancellationToken cancellationToken = default)
        {
            var url = (_config["Supabase:Url"] ?? string.Empty).TrimEnd('/');
            var anonKey = _config["Supabase:AnonKey"] ?? string.Empty;
            if (url.Length == 0 || anonKey.Length == 0)
                return SignUpResult.Failed("Creating accounts is not set up on this computer: Supabase:Url and Supabase:AnonKey are missing.");

            try
            {
                // A driver who was declined earlier still has a sign-in account. If the
                // password matches, reuse it rather than failing with "already registered".
                var existing = await TrySignInAsync(url, anonKey, email, password, cancellationToken);
                if (existing is not null) return SignUpResult.Created(existing.Value);

                using var request = new HttpRequestMessage(HttpMethod.Post, $"{url}/auth/v1/signup")
                {
                    Content = JsonContent.Create(new
                    {
                        email,
                        password,
                        data = new Dictionary<string, string?>
                        {
                            ["full_name"] = fullName,
                            ["phone_number"] = phoneNumber,
                        },
                    }),
                };
                request.Headers.Add("apikey", anonKey);

                using var response = await _http.SendAsync(request, cancellationToken);
                var body = await response.Content.ReadAsStringAsync(cancellationToken);

                if (!response.IsSuccessStatusCode)
                    return SignUpResult.Failed(Explain(body));

                return ReadNewAccount(body)
                    ?? SignUpResult.Failed("This email already has an account. Log in with it, or use a different email.");
            }
            catch (HttpRequestException)
            {
                return SignUpResult.Failed("Could not reach Supabase to create the account. Please try again.");
            }
        }

        private async Task<Guid?> TrySignInAsync(string url, string anonKey, string email, string password,
            CancellationToken cancellationToken)
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, $"{url}/auth/v1/token?grant_type=password")
            {
                Content = JsonContent.Create(new { email, password }),
            };
            request.Headers.Add("apikey", anonKey);

            using var response = await _http.SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode) return null;
            return ReadUserId(await response.Content.ReadAsStringAsync(cancellationToken), requireIdentities: false);
        }

        // With email confirmation on, Supabase answers with the user at the top level;
        // with it off, the answer is a session with the user inside. An email that is
        // already taken comes back as a user with no identities, which is not a new account.
        private static SignUpResult? ReadNewAccount(string body)
        {
            var id = ReadUserId(body, requireIdentities: true);
            return id is null ? null : SignUpResult.Created(id.Value);
        }

        private static Guid? ReadUserId(string body, bool requireIdentities)
        {
            try
            {
                using var doc = JsonDocument.Parse(body);
                var root = doc.RootElement;
                var user = root.TryGetProperty("user", out var inner) && inner.ValueKind == JsonValueKind.Object
                    ? inner
                    : root;

                if (requireIdentities
                    && user.TryGetProperty("identities", out var identities)
                    && identities.ValueKind == JsonValueKind.Array
                    && identities.GetArrayLength() == 0)
                    return null;

                return user.TryGetProperty("id", out var id) && Guid.TryParse(id.GetString(), out var guid)
                    ? guid
                    : null;
            }
            catch (JsonException)
            {
                return null;
            }
        }

        // Supabase's own wording where it is useful, never anything from our settings.
        private static string Explain(string body)
        {
            string text = string.Empty;
            try
            {
                using var doc = JsonDocument.Parse(body);
                foreach (var name in new[] { "msg", "message", "error_description", "error" })
                    if (doc.RootElement.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String)
                    {
                        text = value.GetString() ?? string.Empty;
                        break;
                    }
            }
            catch (JsonException) { }

            if (text.Contains("already", StringComparison.OrdinalIgnoreCase))
                return "This email already has an account. Log in with it, or use a different email.";
            if (text.Contains("password", StringComparison.OrdinalIgnoreCase))
                return "That password was not accepted. Choose a longer one with letters and numbers.";
            if (text.Contains("rate", StringComparison.OrdinalIgnoreCase) || text.Contains("seconds", StringComparison.OrdinalIgnoreCase))
                return "Too many attempts. Please wait a minute and try again.";
            return "Could not create the account. Please check your details and try again.";
        }
    }
}
