using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;
using SupaClean.Application.Interfaces;
using SupaClean.Persistence;
using SupaClean.Application.Services;
using SupaClean.Domain.Exceptions;  
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddInfrastructure(
    builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException("Connection string 'Default' is missing."));

builder.Services.AddScoped<ICustomerService, CustomerService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IServiceCatalog, ServiceCatalog>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IDeliveryZoneService, DeliveryZoneService>();

builder.Services.AddControllers()
    .AddJsonOptions(o =>
        o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter())); // enums as "Eft", not 0

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Checks the Supabase login token the Flutter app sends. Supabase signs tokens
// with a public key, so no secret is needed here, only the project address.
var supabaseUrl = builder.Configuration["Supabase:Url"]
    ?? "https://anuayvbkxntskuuewxae.supabase.co";
var supabaseAuth = $"{supabaseUrl.TrimEnd('/')}/auth/v1";
JsonWebKeySet? supabaseKeys = null;
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidIssuer = supabaseAuth,
            ValidAudience = "authenticated",
            IssuerSigningKeyResolver = (_, _, kid, _) =>
            {
                supabaseKeys ??= new JsonWebKeySet(new HttpClient()
                    .GetStringAsync($"{supabaseAuth}/.well-known/jwks.json")
                    .GetAwaiter().GetResult());
                return supabaseKeys.GetSigningKeys();
            }
        };
    });
builder.Services.AddAuthorization();

// Lets the Flutter web app (Chrome) call the API. The API uses a bearer token,
// not cookies, so allowing any origin is fine for testing; tighten before launch.
builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
    p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

app.UseCors();

// One error format for every failure: { "code": "...", "message": "..." }
app.UseExceptionHandler(errorApp => errorApp.Run(async ctx =>
{
    var ex = ctx.Features.Get<IExceptionHandlerFeature>()?.Error;
    var (status, code) = ex switch
    {
        BusinessRuleException => (400, "business_rule"),
        KeyNotFoundException => (404, "not_found"),
        _ => (500, "server_error")
    };
    ctx.Response.StatusCode = status;
    await ctx.Response.WriteAsJsonAsync(new
    {
        code,
        message = status == 500 ? "Something went wrong." : ex!.Message
    });
}));

// Not inside "if Development", so it also works once hosted
app.UseSwagger();
app.UseSwaggerUI();

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();