using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.Interfaces;
using SupaClean.Application.Services;
using SupaClean.Domain.Exceptions;
using SupaClean.Persistence;
using SupaClean.WebApi.Security;
using SupaClean.Persistence.Storage;
using System.Security.Claims;
using System.Text;
using System.Text.Json.Serialization;


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Paste the Supabase access token"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } },
            Array.Empty<string>()
        }
    });
});

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
builder.Services.AddHttpClient<IProofStorage,SupabaseProofStorage>();

// ---- Supabase login validation ----
var supabaseUrl = builder.Configuration["Supabase:Url"]
    ?? throw new InvalidOperationException("Supabase:Url is missing.");
var jwtSecret = builder.Configuration["Supabase:JwtSecret"];   // only for projects on the legacy secret

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.MapInboundClaims = false;   // keep Supabase's "sub" claim name
        var p = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = $"{supabaseUrl}/auth/v1",
            ValidateAudience = true,
            ValidAudience = "authenticated",
            ValidateLifetime = true,
            RoleClaimType = ClaimTypes.Role   // ignore Supabase's own "role" claim ("authenticated")
        };

        if (!string.IsNullOrWhiteSpace(jwtSecret))
            p.IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret));
        else
            p.IssuerSigningKeyResolver = (_, _, _, _) =>
                SupabaseKeys.Get($"{supabaseUrl}/auth/v1/.well-known/jwks.json");

        o.TokenValidationParameters = p;
    });

builder.Services.AddScoped<IClaimsTransformation, RoleClaimsTransformation>();
builder.Services.AddAuthorization();

builder.Services.AddCors(o => o.AddPolicy("blazor", p =>
    p.WithOrigins("https://localhost:7200")   // your teammate's app URL; add the hosted one later
     .AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

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

app.UseSwagger();
app.UseSwaggerUI();

app.UseHttpsRedirection();
app.UseCors("blazor");
app.UseAuthentication();     
app.UseAuthorization();
app.MapControllers();

app.Run();