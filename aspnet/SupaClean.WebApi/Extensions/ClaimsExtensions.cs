namespace SupaClean.WebApi.Extensions
{
    using System.Security.Claims;

    public static class ClaimsExtensions
    {
        public static Guid GetUserId(this ClaimsPrincipal user)
        {
            var sub = user.FindFirstValue("sub") ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(sub, out var id) ? id : Guid.Empty;
        }
    }
}
