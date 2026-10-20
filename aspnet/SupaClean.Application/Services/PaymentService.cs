using SupaClean.Application.Contracts;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Application.DTOs;
using SupaClean.Application.Interfaces;
using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Services
{
    public class PaymentService : IPaymentService 
    {
        private readonly IPayment _paymentRepository;
        private readonly IOrderRepository _orderRepository;
        private readonly IUnitOfWork _unitOfWork;

        public PaymentService(
            IPayment paymentRepository,
            IOrderRepository orderRepository,
            IUnitOfWork unitOfWork)
        {
            _paymentRepository = paymentRepository;
            _orderRepository = orderRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<Guid> ProcessPaymentAsync(ProcessPaymentDto dto)
        {
            var order = await _orderRepository.GetByIdAsync(dto.OrderId)
                ?? throw new KeyNotFoundException($"Order with ID {dto.OrderId} was not found.");

            var type = Enum.Parse<PaymentType>(dto.PaymentType);
            var method = Enum.Parse<PaymentMethod>(dto.PaymentMethod);

            var amount = type == PaymentType.DeliveryFee
                ? order.DeliveryFee        
                : order.ItemsTotal;

            var existing = await _paymentRepository.GetByOrderIdAndTypeAsync(dto.OrderId, type);
            if (existing is not null && existing.VerificationStatus != VerificationStatus.Declined)
                throw new BusinessRuleException("A payment of this type already exists for this order.");

            var payment = new Payment(dto.OrderId, type, amount, method,
                                      dto.BankReference, dto.ProofOfPaymentReference);

            await _paymentRepository.AddAsync(payment);
            await _unitOfWork.SaveChangesAsync();
            return payment.PaymentId;
        }

        public async Task VerifyPaymentAsync(Guid paymentId, Guid verifiedByEmployeeId)
        {
            var payment = await _paymentRepository.GetByIdAsync(paymentId)
                ?? throw new KeyNotFoundException($"Payment with ID {paymentId} was not found.");

            payment.Verify(verifiedByEmployeeId);

            _paymentRepository.Update(payment);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task RequestNewProofOfPaymentAsync(Guid paymentId, string reason)
        {
            var payment = await _paymentRepository.GetByIdAsync(paymentId)
                ?? throw new KeyNotFoundException($"Payment with ID {paymentId} was not found.");

            payment.RejectProof(reason);

            _paymentRepository.Update(payment);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<IEnumerable<PaymentDto>> GetPaymentsByOrderIdAsync(Guid orderId)
        {
            var payments = await _paymentRepository.GetByOrderIdAsync(orderId);
            return payments.Select(MapToDto);
        }

        public async Task SubmitNewProofAsync(Guid paymentId, string proofOfPayment)
        {
            var payment = await _paymentRepository.GetByIdAsync(paymentId)
                ?? throw new KeyNotFoundException($"Payment with ID {paymentId} was not found.");

            payment.SubmitNewProof(proofOfPayment);

            _paymentRepository.Update(payment);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<IEnumerable<PaymentDto>> GetUnverifiedPaymentsAsync()
        {
            var payments = await _paymentRepository.GetUnverifiedPaymentsAsync();
            return payments.Select(MapToDto);
        }

        private static PaymentDto MapToDto(Payment payment)
        {
            return new PaymentDto(
          payment.PaymentId,
          payment.OrderId,
          payment.Amount,
          payment.PaymentMethod.ToString(),
          payment.PaymentStatus.ToString(),
          payment.VerificationStatus.ToString(),
          payment.ProofOfPayment,
          payment.RejectionReason,
          payment.PaymentDate,
          payment.VerifiedAt
      );
        }
    }
}
