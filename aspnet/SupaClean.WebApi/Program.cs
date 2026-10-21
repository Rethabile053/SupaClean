using Microsoft.AspNetCore.Diagnostics;
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

var app = builder.Build();

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
app.UseAuthorization();
app.MapControllers();

app.Run();