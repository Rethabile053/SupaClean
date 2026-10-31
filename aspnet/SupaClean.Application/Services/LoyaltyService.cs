using SupaClean.Application.Contracts;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Rules;

namespace SupaClean.Application.Services
{
    public class LoyaltyService : ILoyaltyService
    {
        private readonly IPointsRepository _points;
        private readonly INotificationRepository _notifications;

        public LoyaltyService(IPointsRepository points, INotificationRepository notifications)
        {
            _points = points;
            _notifications = notifications;
        }

        public async Task<PointsSummaryDto> GetSummaryAsync(Guid customerId)
        {
            var balance = await _points.GetBalanceAsync(customerId);
            var history = (await _points.GetHistoryAsync(customerId))
                .Select(t => new PointsEntryDto(t.Kind.ToString(), t.Points, t.Description, t.OrderId, t.CreatedAt))
                .ToList();

            return new PointsSummaryDto(
                balance,
                LoyaltyRules.RandValue(balance),
                LoyaltyRules.PointsPerRandRedeemed,
                LoyaltyRules.RandSpentPerPointEarned,
                LoyaltyRules.MaxShareOfItemsPaidWithPoints,
                history);
        }

        public async Task<decimal> RedeemForNewOrderAsync(Order order)
        {
            var balance = await _points.GetBalanceAsync(order.CustomerId);
            var rand = LoyaltyRules.MaxDiscount(order.ItemsTotal, balance);
            if (rand <= 0) return 0;

            order.ApplyPointsDiscount(rand);
            await _points.AddAsync(new PointsTransaction(order.CustomerId, order.OrderId, PointsKind.Redeemed,
                -LoyaltyRules.PointsFor(rand), "Used on a new order"));
            return rand;
        }

        public async Task AwardForCompletedOrderAsync(Order order)
        {
            if (await _points.ExistsAsync(order.OrderId, PointsKind.Earned)) return;

            var earned = LoyaltyRules.PointsEarned(order.OrderPaymentDue);
            if (earned <= 0) return;

            await _points.AddAsync(new PointsTransaction(order.CustomerId, order.OrderId, PointsKind.Earned,
                earned, $"Order {order.OrderNumber} delivered"));
            await _notifications.AddAsync(new Notification(order.CustomerId, "You earned points",
                $"Order {order.OrderNumber} is done. You earned {earned} points.", order.OrderId));
        }

        public async Task RefundForOrderAsync(Order order)
        {
            if (await _points.ExistsAsync(order.OrderId, PointsKind.Refunded)) return;

            var spent = -await _points.SumForOrderAsync(order.OrderId, PointsKind.Redeemed);
            if (spent <= 0) return;

            await _points.AddAsync(new PointsTransaction(order.CustomerId, order.OrderId, PointsKind.Refunded,
                spent, $"Order {order.OrderNumber} did not go ahead"));
            await _notifications.AddAsync(new Notification(order.CustomerId, "Points returned",
                $"Order {order.OrderNumber} did not go ahead, so your {spent} points are back.", order.OrderId));
        }
    }
}
