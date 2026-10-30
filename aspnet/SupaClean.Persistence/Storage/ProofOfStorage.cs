using global::SupaClean.Application.Contracts.Repositories;
using global::SupaClean.Domain.Exceptions;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.Configuration;
using System.Text.Json.Serialization;



namespace SupaClean.Persistence.Storage
{
    
   

    public class SupabaseProofStorage : IProofStorage
    {
        private readonly HttpClient _http;
        private readonly IConfiguration _config;

        public SupabaseProofStorage(HttpClient http, IConfiguration config)
        {
            _http = http;
            _config = config;
        }

        public async Task<string> GetSignedUrlAsync(string path, int expiresInSeconds)
        {
            // read the settings here, not in the constructor, so a missing key
            // can't break the rest of the app
            var url = _config["Supabase:Url"]
                ?? throw new InvalidOperationException("Supabase:Url is missing.");
            var key = _config["Supabase:ServiceRoleKey"]
                ?? throw new InvalidOperationException("Supabase:ServiceRoleKey is missing.");
            var bucket = _config["Supabase:ProofBucket"] ?? "payment-proofs";

            if (string.IsNullOrWhiteSpace(path) || path.Contains("..") || path.StartsWith('/'))
                throw new BusinessRuleException("Invalid proof of payment path.");

            var encodedPath = string.Join("/", path.Split('/').Select(Uri.EscapeDataString));
            var storage = $"{url.TrimEnd('/')}/storage/v1";

            var request = new HttpRequestMessage(HttpMethod.Post,
                $"{storage}/object/sign/{bucket}/{encodedPath}")
            {
                Content = JsonContent.Create(new { expiresIn = expiresInSeconds })
            };
            request.Headers.Add("apikey", key);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", key);

            var response = await _http.SendAsync(request);
            if (!response.IsSuccessStatusCode)
                throw new BusinessRuleException("Could not open the proof of payment. Please try again.");

            var body = await response.Content.ReadFromJsonAsync<SignResponse>();
            if (string.IsNullOrWhiteSpace(body?.SignedUrl))
                throw new BusinessRuleException("Could not open the proof of payment. Please try again.");

            return $"{storage}{body.SignedUrl}";
        }

        private class SignResponse
        {
            [JsonPropertyName("signedURL")]
            public string? SignedUrl { get; set; }
        }
    }
}
