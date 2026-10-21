using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;

namespace SupaClean.WebApi.Controllers
{
    [ApiController]
    [Route("api/v1/delivery-zones")]
    [AllowAnonymous]
    public class DeliveryZonesController : ControllerBase
    {
        private readonly IDeliveryZoneService _zones;
        public DeliveryZonesController(IDeliveryZoneService zones) => _zones = zones;

        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<DeliveryZoneDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<DeliveryZoneDto>>> GetActive()
            => Ok(await _zones.GetActiveZonesAsync());
    }
}
