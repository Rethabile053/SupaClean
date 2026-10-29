using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Services
{
    public class ServiceCatalog : IServiceCatalog
    {
        private readonly IServiceRepository _serviceRepository;
        private readonly IUnitOfWork _unitOfWork;

        public ServiceCatalog(IServiceRepository serviceRepository, IUnitOfWork unitOfWork)
        {
            _serviceRepository = serviceRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<IEnumerable<ServiceDto>> GetActiveServicesAsync()
        {
            var services = await _serviceRepository.GetActiveServicesAsync();
            return services.Select(MapToDto);
        }

        public async Task<IEnumerable<ServiceDto>> GetAllServicesAsync()
        {
            var services = await _serviceRepository.GetAllAsync();
            return services.Select(MapToDto);
        }

        public async Task<Guid> CreateServiceAsync(CreateServiceDto dto)
        {
            var service = new Service(
                serviceName: dto.Name,
                price: dto.BasePrice,
                turnaroundDays: dto.TurnaroundDays,
                serviceDescription: string.IsNullOrWhiteSpace(dto.Description)
                    ? null
                    : dto.Description.Trim());

            await _serviceRepository.AddAsync(service);
            await _unitOfWork.SaveChangesAsync();
            return service.ServiceId;
        }

        public async Task DeleteServiceAsync(Guid serviceId)
        {
            var service = await GetOrThrowAsync(serviceId);

            if (await _serviceRepository.IsUsedByOrdersAsync(serviceId))
                throw new BusinessRuleException(
                    $"\"{service.ServiceName}\" is used by existing orders, so it cannot be deleted. Make it inactive instead.");

            await _serviceRepository.Delete(service);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task UpdateServicePriceAsync(Guid serviceId, decimal newPrice)
        {
            var service = await GetOrThrowAsync(serviceId);
            service.UpdatePrice(newPrice);
            await _serviceRepository.Update(service);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task UpdateServiceTurnaroundAsync(Guid serviceId, int days)
        {
            var service = await GetOrThrowAsync(serviceId);
            service.UpdateTurnaround(days);
            await _serviceRepository.Update(service);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task SetServiceActiveAsync(Guid serviceId, bool isActive)
        {
            var service = await GetOrThrowAsync(serviceId);
            if (isActive) service.Activate(); else service.Deactivate();
            await _serviceRepository.Update(service);
            await _unitOfWork.SaveChangesAsync();
        }

        private async Task<Service> GetOrThrowAsync(Guid serviceId)
            => await _serviceRepository.GetByIdAsync(serviceId)
               ?? throw new KeyNotFoundException($"Service with ID {serviceId} was not found.");

        private static ServiceDto MapToDto(Service s) => new(
            s.ServiceId, s.ServiceName, s.ServiceDescription, s.Price,
            s.TurnaroundDays, s.IsActive);
    }
}