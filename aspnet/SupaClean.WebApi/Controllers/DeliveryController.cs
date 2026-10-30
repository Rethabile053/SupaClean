using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.WebApi.Extensions;



namespace SupaClean.WebApi.Controllers
{
  
    [ApiController]
    [Route("api/v1/driver")]
    [Authorize(Roles = "Driver,Admin")]      // Admin included so you can test with one account
    public class DriverController : ControllerBase
    {
        private readonly IDeliveryService _delivery;
        public DriverController(IDeliveryService delivery) => _delivery = delivery;

        [HttpGet("stops")]
        [ProducesResponseType(typeof(IEnumerable<DriverStopDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<DriverStopDto>>> GetStops()
            => Ok(await _delivery.GetStopsAsync());

        [HttpPost("orders/{orderId:guid}/collected")]
        public async Task<IActionResult> Collected(Guid orderId)
        {
            await _delivery.MarkCollectedAsync(orderId);
            return NoContent();
        }

        [HttpPost("orders/{orderId:guid}/cash-collected")]
        public async Task<IActionResult> CashCollected(Guid orderId, CashCollectedDto dto)
        {
            await _delivery.RecordCashCollectedAsync(orderId, User.GetUserId(), dto.Amount);
            return NoContent();
        }

        [HttpPost("orders/{orderId:guid}/delivered")]
        public async Task<IActionResult> Delivered(Guid orderId)
        {
            await _delivery.MarkDeliveredAsync(orderId);
            return NoContent();
        }
    }
}
