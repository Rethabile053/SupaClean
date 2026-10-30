using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Configuration;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;

namespace SupaClean.Persistence.Auth
{
    // Creates staff sign-in accounts with Supabase's admin API. That needs the project's
    // service-role key, which lets the holder manage every account, so it is read from
    // configuration (user-secrets or the host's environment) and is only ever sent to
    // Supabase. It must never be written into an error message or a log line.
    public class SupabaseStaffAccountProvisioner : IStaffAccountProvisioner
    {
        private readonly HttpClient _http;
        private readonly IConfiguration _config;

        public SupabaseStaffAccountProvisioner(HttpClient http, IConfiguration config)
        {
            _http = http;
            _config = config;
        }

        public async Task<StaffAccountResult> CreateAsync(string email, string password, string fullName,
            string? phoneNumber, CancellationToken cancellationToken = default)
        {
            if (!TryGetSettings(out var url, out var key))
                return StaffAccountResult.Failed(
                    "Adding drivers is not set up on this computer: Supabase:Url and Supabase:ServiceRoleKey are missing.");

            using var request = new HttpRequestMessage(HttpMethod.Post, $"{url}/auth/v1/admin/users")
            {
                Content = JsonContent.Create(new
                {
                    email,
                    password,
                    email_confirm = true,   // can sign in straight away
                    user_metadata = new Dictionary<string, string?>
                    {
                        ["full_name"] = fullName,
                        ["phone_number"] = phoneNumber,
                    },
                }),
            };
            Authorize(request, key);

            HttpResponseMessage response;
            try
            {
                response = await _http.SendAsync(request, cancellationToken);
            }
            catch (HttpRequestException)
            {
                return StaffAccountResult.Failed("Could not reach Supabase to create the account. Please try again.");
            }

            using (response)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken);

                if (response.IsSuccessStatusCode)
                {
                    var id = ReadId(body);
                    return id is null
                        ? StaffAccountResult.Failed("Supabase did not return the new account. Please try again.")
                        : StaffAccountResult.Created(id.Value);
                }

                return StaffAccountResult.Failed(Explain((int)response.StatusCode, body));
            }
        }

        public async Task DeleteAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            if (!TryGetSettings(out var url, out var key)) return;

            using var request = new HttpRequestMessage(HttpMethod.Delete, $"{url}/auth/v1/admin/users/{userId}");
            Authorize(request, key);
            using var response = await _http.SendAsync(request, cancellationToken);
        }

        private bool TryGetSettings(out string url, out string key)
        {
            url = (_config["Supabase:Url"] ?? string.Empty).TrimEnd('/');
            key = _config["Supabase:ServiceRoleKey"] ?? string.Empty;
            return url.Length > 0 && key.Length > 0;
        }

        private static void Authorize(HttpRequestMessage request, string key)
        {
            request.Headers.Add("apikey", key);
            request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", key);
        }

        private static Guid? ReadId(string body)
        {
            try
            {
                using var doc = JsonDocument.Parse(body);
                return doc.RootElement.TryGetProperty("id", out var id) && Guid.TryParse(id.GetString(), out var guid)
                    ? guid
                    : null;
            }
            catch (JsonException)
            {
                return null;
            }
        }

        // A message an admin can act on. Only Supabase's own wording is used, never our settings.
        private static string Explain(int status, string body)
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

            if (status is 401 or 403)
                return "Supabase refused the request: the service key on this computer is not valid.";
            if (text.Contains("already", StringComparison.OrdinalIgnoreCase)
                || text.Contains("exists", StringComparison.OrdinalIgnoreCase))
                return "A login account with that email already exists.";
            if (text.Contains("password", StringComparison.OrdinalIgnoreCase))
                return "Supabase rejected the temporary password. Please try again.";

            return text.Length > 0
                ? $"Supabase could not create the account: {text}"
                : "Supabase could not create the account. Please try again.";
        }
    }
}
