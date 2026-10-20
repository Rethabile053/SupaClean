using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.WebApi.Extensions;

namespace SupaClean.WebApi.Controllers
{
    [ApiController]
    [Route("api/v1/customers")]
    [Authorize]
    public class CustomersController : ControllerBase
    {
        private readonly ICustomerService _customers;
        public CustomersController(ICustomerService customers) => _customers = customers;

        [HttpPost]
        [ProducesResponseType(typeof(Guid), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<Guid>> Register(CreateCustomerDto dto)
            => Ok(await _customers.RegisterCustomerAsync(User.GetUserId(), dto));

        [HttpGet("me")]
        [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<CustomerDto>> GetMe()
            => Ok(await _customers.GetCustomerByUserIdAsync(User.GetUserId())
                  ?? throw new KeyNotFoundException("Customer profile not found."));

        [HttpPut("me")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> UpdateMe(UpdateCustomerDto dto)
        {
            await _customers.UpdateCustomerProfileAsync(User.GetUserId(), dto);
            return NoContent();
        }
    }
}
