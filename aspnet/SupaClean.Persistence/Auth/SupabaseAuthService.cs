using Microsoft.Extensions.Configuration;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Auth
{
    public class SupabaseStaffAuthService : IStaffAuthService
    {
        private readonly HttpClient _http;
        private readonly IConfiguration _config;
        private readonly IUserRepository _users;

        public SupabaseStaffAuthService(HttpClient http, IConfiguration config, IUserRepository users)
        {
            _http = http;
            _config = config;
            _users = users;
        }

        public async Task<StaffLoginResult> SignInAsync(string email, string password, Role requiredRole)
        {
            var url = _config["Supabase:Url"] ?? throw new InvalidOperationException("Supabase:Url is missing.");
            var anonKey = _config["Supabase:AnonKey"] ?? throw new InvalidOperationException("Supabase:AnonKey is missing.");

            var request = new HttpRequestMessage(HttpMethod.Post,
                $"{url.TrimEnd('/')}/auth/v1/token?grant_type=password")
            {
                Content = JsonContent.Create(new { email = email.Trim(), password })
            };
            request.Headers.Add("apikey", anonKey);

            var response = await _http.SendAsync(request);
            if (!response.IsSuccessStatusCode)
                return new StaffLoginResult(false, "Invalid email or password.", null);

            var body = await response.Content.ReadFromJsonAsync<TokenResponse>();
            if (body?.User?.Id is null)
                return new StaffLoginResult(false, "Login failed. Please try again.", null);

            // the role comes from OUR Users table, not from anything the user can edit
            var profile = await _users.GetProfileAsync(body.User.Id.Value);
            if (profile is not null && profile.Role == Role.PendingDriver && requiredRole == Role.Driver)
                return new StaffLoginResult(false, "Your account is waiting for an admin to approve it. Please try again later.", null);

            // TEMPORARY: shows exactly why access was refused
            if (profile is null || profile.Role != requiredRole)
                return new StaffLoginResult(false, "This account does not have access to this portal.", null);

            return new StaffLoginResult(true, null, profile);

        }

        private class TokenResponse
        {
            [JsonPropertyName("user")] public SupabaseUser? User { get; set; }
        }

        private class SupabaseUser
        {
            [JsonPropertyName("id")] public Guid? Id { get; set; }
        }
    }
}
