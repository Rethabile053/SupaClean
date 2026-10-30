using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.WebApi.Extensions;

namespace SupaClean.WebApi.Controllers
{
    [ApiController]
    [Route("api/v1/devices")]
    [Authorize]
    public class DeviceController : ControllerBase
    {
        private readonly IDeviceService _devices;
        private readonly ICustomerService _customers;

        public DeviceController(IDeviceService devices, ICustomerService customers)
        {
            _devices = devices;
            _customers = customers;
        }

        // The app sends its Firebase token here after sign-in, so pushes for
        // this customer reach this phone.
        [HttpPost]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Register(RegisterDeviceDto dto)
        {
            var customer = await _customers.GetCustomerByUserIdAsync(User.GetUserId())
                ?? throw new KeyNotFoundException("Customer profile not found.");

            await _devices.RegisterAsync(customer.CustomerId, dto);
            return NoContent();
        }
    }
}
