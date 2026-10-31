using SupaClean.Application.DTOs;
using SupaClean.Domain.Entities;

namespace SupaClean.Application.Interfaces
{
    // The three order methods only queue changes: the caller saves them in the
    // same unit of work as the order, so the order and its points never disagree.
    public interface ILoyaltyService
    {
        Task<PointsSummaryDto> GetSummaryAsync(Guid customerId);

        // Takes the biggest allowed discount off a new order. Returns the rand taken off.
        Task<decimal> RedeemForNewOrderAsync(Order order);

        // Gives points once, when the order is delivered or handed over.
        Task AwardForCompletedOrderAsync(Order order);

        // Gives spent points back once, when the order is cancelled or rejected.
        Task RefundForOrderAsync(Order order);
    }
}
