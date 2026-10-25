using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using SupaClean.Application.Contracts.Repositories;   // IUserRepository
using SupaClean.WebApi.Extensions;                    // GetUserId()


namespace SupaClean.WebApi.Security
{
   

    public class RoleClaimsTransformation : IClaimsTransformation
    {
        private readonly IUserRepository _users;
        public RoleClaimsTransformation(IUserRepository users) => _users = users;

        public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
        {
            if (principal.Identity is not ClaimsIdentity identity || !identity.IsAuthenticated)
                return principal;
            if (identity.HasClaim(c => c.Type == ClaimTypes.Role))
                return principal;

            var userId = principal.GetUserId();
            if (userId == Guid.Empty) return principal;

            var role = await _users.GetRoleAsync(userId);
            if (role is not null)
                identity.AddClaim(new Claim(ClaimTypes.Role, role.Value.ToString()));

            return principal;
        }
    }
}
