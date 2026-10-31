namespace SupaClean.Domain.Rules
{
    // The points scheme in one place, so changing a rate means changing one line.
    public static class LoyaltyRules
    {
        public const int PointsPerRandRedeemed = 10;        // 10 points are worth R1 off
        public const decimal RandSpentPerPointEarned = 2m;  // 1 point for every R2 paid (about 5% back)
        public const decimal MaxShareOfItemsPaidWithPoints = 0.5m;   // points never cover more than half

        // Points earned for an order, from what the customer actually paid for the laundry.
        public static int PointsEarned(decimal amountPaid)
            => amountPaid <= 0 ? 0 : (int)Math.Floor(amountPaid / RandSpentPerPointEarned);

        public static decimal RandValue(int points)
            => points <= 0 ? 0 : Math.Floor(points / (decimal)PointsPerRandRedeemed);

        // The largest whole-rand discount allowed on this order, given the balance.
        public static decimal MaxDiscount(decimal itemsTotal, int balance)
        {
            var cap = Math.Floor(itemsTotal * MaxShareOfItemsPaidWithPoints);
            return Math.Max(0, Math.Min(RandValue(balance), cap));
        }

        public static int PointsFor(decimal rand) => (int)(rand * PointsPerRandRedeemed);
    }
}
