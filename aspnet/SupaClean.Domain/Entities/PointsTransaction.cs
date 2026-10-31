using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Domain.Entities
{
    // One line in a customer's points history. The balance is the sum of these,
    // so it can always be explained and cannot drift.
    public class PointsTransaction
    {
        public const int MaxDescriptionLength = 200;

        public Guid PointsTransactionId { get; private set; }
        public Guid CustomerId { get; private set; }
        public Guid? OrderId { get; private set; }
        public PointsKind Kind { get; private set; }
        public int Points { get; private set; }               // positive adds, negative spends
        public string Description { get; private set; } = string.Empty;
        public DateTime CreatedAt { get; private set; }

        private PointsTransaction() { }

        public PointsTransaction(Guid customerId, Guid? orderId, PointsKind kind, int points, string description)
        {
            if (customerId == Guid.Empty)
                throw new BusinessRuleException("Points must belong to a customer.");
            if (points == 0)
                throw new BusinessRuleException("A points entry cannot be zero.");
            if (kind == PointsKind.Redeemed && points > 0)
                throw new BusinessRuleException("Redeemed points must be taken off.");
            if (kind != PointsKind.Redeemed && points < 0)
                throw new BusinessRuleException("Earned and refunded points must be added.");

            PointsTransactionId = Guid.NewGuid();
            CustomerId = customerId;
            OrderId = orderId;
            Kind = kind;
            Points = points;
            Description = description.Length > MaxDescriptionLength ? description[..MaxDescriptionLength] : description;
            CreatedAt = DateTime.UtcNow;
        }
    }
}
