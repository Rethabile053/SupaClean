using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;

namespace SupaClean.Application.Contracts.Repositories
{
    public interface IDeliveryRepository : IRepository<Delivery>
    {
        // The drivers' jobs for these orders, with the driver and their user loaded.
        Task<IReadOnlyList<Delivery>> GetForOrdersAsync(IEnumerable<Guid> orderIds);

        // The job of this kind for the order that has not been done yet.
        Task<Delivery?> GetOpenAsync(Guid orderId, DeliveryType type);

        // The jobs this user (a driver) has been given and not yet done.
        Task<IReadOnlyList<Delivery>> GetOpenForUserAsync(Guid userId);
    }
}
