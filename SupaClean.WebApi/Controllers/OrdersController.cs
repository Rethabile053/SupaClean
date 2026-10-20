using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.WebApi.Extensions;

namespace SupaClean.WebApi.Controllers
{
    [ApiController]
    [Route("api/v1/orders")]
    [Authorize]
    public class OrdersController : ControllerBase
    {
        private readonly IOrderService _orders;
        private readonly ICustomerService _customers;

        public OrdersController(IOrderService orders, ICustomerService customers)
        {
            _orders = orders;
            _customers = customers;
        }

        private async Task<CustomerDto> CurrentCustomerAsync()
            => await _customers.GetCustomerByUserIdAsync(User.GetUserId())
               ?? throw new KeyNotFoundException("Customer profile not found.");

        [HttpPost]
        [ProducesResponseType(typeof(Guid), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<Guid>> Create(CreateOrderDTO dto)
        {
            var customer = await CurrentCustomerAsync();
            return Ok(await _orders.CreateOrderAsync(customer.CustomerId, dto));
        }

        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<OrderDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<OrderDto>>> GetMine()
        {
            var customer = await CurrentCustomerAsync();
            return Ok(await _orders.GetCustomerOrdersAsync(customer.CustomerId));
        }

        [HttpGet("{id:guid}")]
        [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<OrderDto>> GetById(Guid id)
        {
            var customer = await CurrentCustomerAsync();
            var order = await _orders.GetOrderByIdAsync(id)
                ?? throw new KeyNotFoundException("Order not found.");

            if (order.CustomerId != customer.CustomerId)
                throw new KeyNotFoundException("Order not found.");   // don't reveal other customers' orders

            return Ok(order);
        }
    }
}
