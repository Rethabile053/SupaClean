using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Services
{
    public class DeliveryZoneService : IDeliveryZoneService
    {
        private readonly IDeliveryZoneRepository _zones;
        private readonly IUnitOfWork _unitOfWork;

        public DeliveryZoneService(IDeliveryZoneRepository zones, IUnitOfWork unitOfWork)
        {
            _zones = zones;
            _unitOfWork = unitOfWork;
        }

        public async Task<IEnumerable<DeliveryZoneDto>> GetActiveZonesAsync()
            => (await _zones.GetActiveZonesAsync()).Select(MapToDto);

        public async Task<IEnumerable<DeliveryZoneDto>> GetAllZonesAsync()
            => (await _zones.GetAllAsync()).Select(MapToDto);

        public async Task UpdateZoneFeeAsync(Guid zoneId, decimal fee)
        {
            var zone = await GetOrThrowAsync(zoneId);
            zone.UpdateFee(fee);
            await _zones.Update(zone);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task SetZoneActiveAsync(Guid zoneId, bool isActive)
        {
            var zone = await GetOrThrowAsync(zoneId);
            if (isActive) zone.Activate(); else zone.Deactivate();
            await _zones.Update(zone);
            await _unitOfWork.SaveChangesAsync();
        }

        private async Task<DeliveryZone> GetOrThrowAsync(Guid zoneId)
            => await _zones.GetByIdAsync(zoneId)
               ?? throw new KeyNotFoundException($"Delivery area {zoneId} was not found.");

        private static DeliveryZoneDto MapToDto(DeliveryZone z) => new(z.ZoneId, z.Name, z.Fee, z.IsActive);
    }
}
