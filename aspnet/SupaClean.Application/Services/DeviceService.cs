using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;

namespace SupaClean.Application.Services
{
    public class DeviceService : IDeviceService
    {
        private readonly IDeviceTokenRepository _devices;
        private readonly IUnitOfWork _unitOfWork;

        public DeviceService(IDeviceTokenRepository devices, IUnitOfWork unitOfWork)
        {
            _devices = devices;
            _unitOfWork = unitOfWork;
        }

        public async Task RegisterAsync(Guid customerId, RegisterDeviceDto dto)
        {
            var token = DeviceToken.CleanToken(dto.Token);
            var existing = await _devices.GetByTokenAsync(token);

            if (existing is null)
                await _devices.AddAsync(new DeviceToken(customerId, token, dto.Platform));
            else
                existing.AssignTo(customerId, dto.Platform);

            await _unitOfWork.SaveChangesAsync();
        }
    }
}
