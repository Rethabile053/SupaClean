using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using SupaClean.Application.Contracts;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.Interfaces;
using SupaClean.Application.Services;
using SupaClean.Blazor.Components;
using SupaClean.Domain.Enums;
using SupaClean.Persistence;
using SupaClean.Persistence.Auth;
using SupaClean.Persistence.Storage;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddInfrastructure(
    builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException("Connection string 'Default' is missing."));

builder.Services.AddScoped<ICustomerService, CustomerService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IServiceCatalog, ServiceCatalog>();
builder.Services.AddScoped<IDeliveryZoneService, DeliveryZoneService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IDeliveryService, DeliveryService>();
builder.Services.AddScoped<IDriverAssignmentService, DriverAssignmentService>();
builder.Services.AddScoped<IDriverRegistrationService, DriverRegistrationService>();
builder.Services.AddScoped<IProfileService, ProfileService>();
builder.Services.AddHttpClient<IDriverSignUp, SupabaseDriverSignUp>();
builder.Services.AddHttpClient<IProofStorage, SupabaseProofStorage>();
builder.Services.AddHttpClient<IStaffAuthService, SupabaseStaffAuthService>();


builder.Services.AddCascadingAuthenticationState();
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(o =>
    {
        o.LoginPath = "/admin-login";
        o.AccessDeniedPath = "/admin-login";
        // Send people to the log in page for the part of the site they tried to open.
        static string LoginFor(string path) =>
            path.StartsWith("/driver", StringComparison.OrdinalIgnoreCase) ? "/driver-login" : "/admin-login";
        o.Events.OnRedirectToLogin = ctx =>
        {
            ctx.Response.Redirect(LoginFor(ctx.Request.Path));
            return Task.CompletedTask;
        };
        o.Events.OnRedirectToAccessDenied = ctx =>
        {
            ctx.Response.Redirect(LoginFor(ctx.Request.Path));
            return Task.CompletedTask;
        };
        o.ExpireTimeSpan = TimeSpan.FromHours(8);
        o.SlidingExpiration = true;
    });
builder.Services.AddAuthorization();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();
app.UseAntiforgery();

app.MapPost("/auth/login", async (HttpContext ctx, IStaffAuthService auth) =>
{
    var form = await ctx.Request.ReadFormAsync();
    var portal = form["portal"].ToString();
    var required = portal == "driver" ? Role.Driver : Role.Admin;
    var loginPage = portal == "driver" ? "/driver-login" : "/admin-login";

    var result = await auth.SignInAsync(form["email"].ToString(), form["password"].ToString(), required);
    if (!result.Success)
        return Results.Redirect($"{loginPage}?error={Uri.EscapeDataString(result.Error ?? "Login failed.")}");

    var claims = new List<Claim>
    {
        new("sub", result.Profile!.UserId.ToString()),
        new(ClaimTypes.Name, result.Profile.FullName),
        new(ClaimTypes.Role, required.ToString())
    };
    var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
    await ctx.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(identity));

    return Results.Redirect(portal == "driver" ? "/driver/deliveries" : "/orders");   // use his real @page routes
}).DisableAntiforgery();

app.MapPost("/auth/logout", async (HttpContext ctx) =>
{
    // Send people back to the log in page they came from: drivers to theirs, everyone else to the admin one.
    var loginPage = ctx.User.IsInRole(Role.Driver.ToString()) ? "/driver-login" : "/admin-login";
    await ctx.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
    return Results.Redirect(loginPage);
}).DisableAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();