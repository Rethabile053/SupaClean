using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using SupaClean.WebApi.Extensions;



namespace SupaClean.WebApi.Controllers
{

    [ApiController]
    [Route("api/v1/admin/payments")]
    [Authorize(Roles = "Admin")]
    public class AdminPaymentsController : ControllerBase
    {
        private readonly IPaymentService _payments;
        public AdminPaymentsController(IPaymentService payments) => _payments = payments;

        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<PaymentReviewDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<PaymentReviewDto>>> GetAll(
            [FromQuery] string? search, [FromQuery] string? type,
            [FromQuery] string? method, [FromQuery] string? verification)
            => Ok(await _payments.GetAllPaymentsAsync(search, type, method, verification));

        [HttpGet("unverified")]
        [ProducesResponseType(typeof(IEnumerable<PaymentReviewDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<PaymentReviewDto>>> GetUnverified()
            => Ok(await _payments.GetPaymentsForReviewAsync());

        [HttpGet("{id:guid}/proof-url")]
        [ProducesResponseType(typeof(ProofUrlDto), StatusCodes.Status200OK)]
        public async Task<ActionResult<ProofUrlDto>> GetProofUrl(Guid id)
            => Ok(new ProofUrlDto(await _payments.GetProofUrlAsync(id), 300));

        [HttpPost("{id:guid}/verify")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> Verify(Guid id, VerifyPaymentDto dto)
        {
            await _payments.VerifyPaymentAsync(id, User.GetUserId(), dto.ConfirmedAmount);
            return NoContent();
        }

        [HttpPost("{id:guid}/reject")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> Reject(Guid id, RejectProofDto dto)
        {
            await _payments.RequestNewProofOfPaymentAsync(id, dto.Reason);
            return NoContent();
        }
    }

    [ApiController]
    [Route("api/v1/admin/orders")]
    [Authorize(Roles = "Admin")]
    public class AdminOrdersController : ControllerBase
    {
        private readonly IOrderService _orders;
        public AdminOrdersController(IOrderService orders) => _orders = orders;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<OrderDto>>> GetAll()
            => Ok(await _orders.GetAllOrdersAsync());

        [HttpGet("{id:guid}")]
        public async Task<ActionResult<OrderDto>> GetById(Guid id)
            => Ok(await _orders.GetOrderByIdAsync(id) ?? throw new KeyNotFoundException("Order not found."));

        [HttpGet("by-number/{orderNumber}")]
        public async Task<ActionResult<OrderDto>> GetByNumber(string orderNumber)
            => Ok(await _orders.GetOrderByNumberAsync(orderNumber) ?? throw new KeyNotFoundException("Order not found."));

        [HttpPost("{id:guid}/ticket")]
        public async Task<IActionResult> LinkTicket(Guid id, LinkTicketDto dto)
        {
            await _orders.LinkPhysicalTicketAsync(id, dto.TicketNumber);
            return NoContent();
        }

        [HttpPost("{id:guid}/status")]
        public async Task<IActionResult> UpdateStatus(Guid id, UpdateStatusDto dto)
        {
            if (!Enum.TryParse<OrderStatus>(dto.Status, true, out var status))
                throw new BusinessRuleException("Invalid order status.");
            await _orders.UpdateOrderStatusAsync(id, status);
            return NoContent();
        }

        [HttpPost("{id:guid}/flag")]
        public async Task<IActionResult> Flag(Guid id, FlagExceptionDto dto)
        {
            await _orders.FlagOrderExceptionAsync(id, dto.Notes);
            return NoContent();
        }
    }

   


    [ApiController]
    [Route("api/v1/admin/customers")]
    [Authorize(Roles = "Admin")]
    public class AdminCustomersController : ControllerBase
    {
        private readonly ICustomerService _customers;
        private readonly IOrderService _orders;

        public AdminCustomersController(ICustomerService customers, IOrderService orders)
        {
            _customers = customers;
            _orders = orders;
        }

        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<CustomerDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<CustomerDto>>> GetAll([FromQuery] string? search)
            => Ok(await _customers.SearchCustomersAsync(search));

        [HttpGet("{id:guid}")]
        [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
        public async Task<ActionResult<CustomerDto>> GetById(Guid id)
            => Ok(await _customers.GetCustomerByIdAsync(id)
                  ?? throw new KeyNotFoundException("Customer not found."));

        [HttpGet("{id:guid}/orders")]
        [ProducesResponseType(typeof(IEnumerable<OrderDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<OrderDto>>> GetOrders(Guid id)
            => Ok(await _orders.GetCustomerOrdersAsync(id));
    }



    /// new 
    [ApiController]
    [Route("api/v1/admin/services")]
    [Authorize(Roles = "Admin")]
    public class AdminServicesController : ControllerBase
    {
        private readonly IServiceCatalog _catalog;
        public AdminServicesController(IServiceCatalog catalog) => _catalog = catalog;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ServiceDto>>> GetAll()
            => Ok(await _catalog.GetAllServicesAsync());

        [HttpPost]
        public async Task<ActionResult<Guid>> Create(CreateServiceDto dto)
            => Ok(await _catalog.CreateServiceAsync(dto));

        [HttpPut("{id:guid}/price")]
        public async Task<IActionResult> UpdatePrice(Guid id, UpdatePriceDto dto)
        {
            await _catalog.UpdateServicePriceAsync(id, dto.Price);
            return NoContent();
        }

        [HttpPut("{id:guid}/turnaround")]
        public async Task<IActionResult> UpdateTurnaround(Guid id, UpdateTurnaroundDto dto)
        {
            await _catalog.UpdateServiceTurnaroundAsync(id, dto.Days);
            return NoContent();
        }

        [HttpPut("{id:guid}/active")]
        public async Task<IActionResult> SetActive(Guid id, SetActiveDto dto)
        {
            await _catalog.SetServiceActiveAsync(id, dto.IsActive);
            return NoContent();
        }

        // Refused (400) when orders use the service: make it inactive instead.
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            await _catalog.DeleteServiceAsync(id);
            return NoContent();
        }
    }

    [ApiController]
    [Route("api/v1/admin/delivery-zones")]
    [Authorize(Roles = "Admin")]
    public class AdminDeliveryZonesController : ControllerBase
    {
        private readonly IDeliveryZoneService _zones;
        public AdminDeliveryZonesController(IDeliveryZoneService zones) => _zones = zones;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<DeliveryZoneDto>>> GetAll()
            => Ok(await _zones.GetAllZonesAsync());

        [HttpPut("{id:guid}/fee")]
        public async Task<IActionResult> UpdateFee(Guid id, UpdateFeeDto dto)
        {
            await _zones.UpdateZoneFeeAsync(id, dto.Fee);
            return NoContent();
        }

        [HttpPut("{id:guid}/active")]
        public async Task<IActionResult> SetActive(Guid id, SetActiveDto dto)
        {
            await _zones.SetZoneActiveAsync(id, dto.IsActive);
            return NoContent();
        }
    }
}
