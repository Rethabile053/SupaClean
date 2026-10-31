namespace SupaClean.Application.DTOs
{
    public record PointsEntryDto(string Kind, int Points, string Description, Guid? OrderId, DateTime CreatedAt);

    // Everything the app needs to show the balance and work out the discount prompt.
    public record PointsSummaryDto(
        int Balance,
        decimal BalanceValue,              // rand the whole balance is worth
        int PointsPerRand,                 // 10 points are worth R1
        decimal RandSpentPerPoint,         // 1 point is earned for every R2 paid
        decimal MaxShareOfItems,           // points can cover up to this share of the laundry price
        List<PointsEntryDto> History);
}
