using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.WebApi.Extensions;

namespace SupaClean.WebApi.Controllers
{
    [ApiController]
    [Route("api/v1")]
    [Authorize]
    public class PaymentsController : ControllerBase
    {
        private readonly IPaymentService _payments;
        public PaymentsController(IPaymentService payments) => _payments = payments;

        [HttpPost("orders/{orderId:guid}/payments")]
        [ProducesResponseType(typeof(Guid), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<Guid>> Submit(Guid orderId, ProcessPaymentDto dto)
            => Ok(await _payments.ProcessPaymentAsync(dto with { OrderId = orderId }));

        [HttpGet("orders/{orderId:guid}/payments")]
        [ProducesResponseType(typeof(IEnumerable<PaymentDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<IEnumerable<PaymentDto>>> GetForOrder(Guid orderId)
            => Ok(await _payments.GetPaymentsByOrderIdAsync(orderId));

        [HttpPut("payments/{paymentId:guid}/proof")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> ResubmitProof(Guid paymentId, ResubmitProofDto dto)
        {
            await _payments.SubmitNewProofAsync(paymentId, dto.ProofOfPayment);
            return NoContent();
        }
    }

    public record ResubmitProofDto(string ProofOfPayment);
}
