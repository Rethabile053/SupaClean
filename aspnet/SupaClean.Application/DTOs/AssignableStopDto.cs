namespace SupaClean.Application.DTOs
{
    // An order waiting for a driver, and who has it if someone does.
    public record AssignableStopDto(
        Guid OrderId,
        string OrderNumber,
        string? TicketNumber,
        string StopType,                 // "Pickup" or "Delivery"
        string CustomerName,
        string? CustomerPhone,
        string City,
        string Address,
        Guid? AssignedDriverUserId,
        string? AssignedDriverName);
}
