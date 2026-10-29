using System;

namespace SupaClean.Application.DTOs
{
    /// <summary>When an order reached a status (UTC).</summary>
    public record OrderStatusChangeDto(string Status, DateTime ChangedAt);
}
