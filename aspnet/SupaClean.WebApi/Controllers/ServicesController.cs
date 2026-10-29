using Microsoft.AspNetCore.Mvc;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.WebApi.Extensions;
using Microsoft.AspNetCore.Authorization;


namespace SupaClean.WebApi.Controllers
{
   

    [ApiController]
    [Route("api/v1/services")]
    [AllowAnonymous]
    public class ServicesController : ControllerBase
    {
        private readonly IServiceCatalog _catalog;
        public ServicesController(IServiceCatalog catalog) => _catalog = catalog;

        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<ServiceDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<ServiceDto>>> GetActive(
            [FromQuery] bool includeInactive = false)
            => Ok(includeInactive
                ? await _catalog.GetAllServicesAsync()      // each has isActive, so the app can show it as unavailable
                : await _catalog.GetActiveServicesAsync());
    }
}
