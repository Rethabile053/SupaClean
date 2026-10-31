namespace SupaClean.Domain.Enums
{
    public enum PointsKind
    {
        Earned,      // an order was delivered
        Redeemed,    // points were taken off an order's price
        Refunded     // the order was cancelled or rejected, so the points came back
    }
}
