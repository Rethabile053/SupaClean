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
        private readonly INotificationRepository _notifications;
        private readonly IProofStorage _proofStorage;
        private readonly IUnitOfWork _unitOfWork;

        public PaymentService(
            IPayment paymentRepository,
            IOrderRepository orderRepository,
            INotificationRepository notifications,
            IProofStorage proofStorage,
            IUnitOfWork unitOfWork)
        {
            _paymentRepository = paymentRepository;
            _orderRepository = orderRepository;
            _notifications = notifications;
            _proofStorage = proofStorage;
            _unitOfWork = unitOfWork;
        }

        public async Task<Guid> ProcessPaymentAsync(ProcessPaymentDto dto)
        {
            var order = await _orderRepository.GetByIdAsync(dto.OrderId)
                ?? throw new KeyNotFoundException($"Order with ID {dto.OrderId} was not found.");

            if (!Enum.TryParse<PaymentType>(dto.PaymentType, true, out var type))
                throw new BusinessRuleException("Invalid payment type.");
            if (!Enum.TryParse<PaymentMethod>(dto.PaymentMethod, true, out var method))
                throw new BusinessRuleException("Invalid payment method.");

            if (type == PaymentType.DeliveryFee && order.DeliveryFee <= 0)
                throw new BusinessRuleException("This order has no delivery fee.");

            var amount = type == PaymentType.DeliveryFee
                ? order.DeliveryFee
                : order.ItemsTotal + order.PickupFee;   // the order payment also covers the pickup fee

            var existing = await _paymentRepository.GetByOrderIdAndTypeAsync(dto.OrderId, type);
            if (existing is not null && existing.VerificationStatus != VerificationStatus.Declined)
                throw new BusinessRuleException("A payment of this type already exists for this order.");

            var payment = new Payment(dto.OrderId, type, amount, method,
                                      dto.BankReference, dto.ProofOfPaymentReference);

            await _paymentRepository.AddAsync(payment);
            await _unitOfWork.SaveChangesAsync();
            return payment.PaymentId;
        }

        public async Task VerifyPaymentAsync(Guid paymentId, Guid verifiedByEmployeeId, decimal confirmedAmount)
        {
            var payment = await _paymentRepository.GetByIdAsync(paymentId)
                ?? throw new KeyNotFoundException($"Payment with ID {paymentId} was not found.");

            if (confirmedAmount != payment.Amount)
                throw new BusinessRuleException(
                    $"The amount you entered (R{confirmedAmount:0.00}) does not match the amount due (R{payment.Amount:0.00}). Reject the proof or ask the customer to correct it.");

            payment.Verify(verifiedByEmployeeId);

            var order = await _orderRepository.GetByIdAsync(payment.OrderId);
            if (order is not null)
            {
                var what = payment.PaymentType == PaymentType.DeliveryFee ? "delivery fee" : "order";
                await _notifications.AddAsync(new Notification(order.CustomerId, "Payment confirmed",
                    $"Your {what} payment for order {order.OrderNumber} has been verified.", order.OrderId));
            }

            await _paymentRepository.Update(payment);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task RequestNewProofOfPaymentAsync(Guid paymentId, string reason)
        {
            var payment = await _paymentRepository.GetByIdAsync(paymentId)
                ?? throw new KeyNotFoundException($"Payment with ID {paymentId} was not found.");

            payment.RejectProof(reason);

            var order = await _orderRepository.GetByIdAsync(payment.OrderId);
            if (order is not null)
                await _notifications.AddAsync(new Notification(order.CustomerId,
                    "Please upload a new proof of payment",
                    $"Order {order.OrderNumber}: {reason.Trim()}", order.OrderId));

            await _paymentRepository.Update(payment);
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

            await _paymentRepository.Update(payment);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<IEnumerable<PaymentReviewDto>> GetPaymentsForReviewAsync()
        {
            var payments = await _paymentRepository.GetUnverifiedPaymentsAsync();
            return payments.Select(MapToReview);
        }

        public async Task<IEnumerable<PaymentReviewDto>> GetAllPaymentsAsync(
            string? search, string? type, string? method, string? verification)
        {
            var items = (await _paymentRepository.GetAllWithDetailsAsync()).Select(MapToReview);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var t = search.Trim();
                items = items.Where(i => i.OrderNumber.Contains(t, StringComparison.OrdinalIgnoreCase)
                                      || i.CustomerName.Contains(t, StringComparison.OrdinalIgnoreCase));
            }
            if (!string.IsNullOrWhiteSpace(type))
                items = items.Where(i => i.PaymentType.Equals(type, StringComparison.OrdinalIgnoreCase));
            if (!string.IsNullOrWhiteSpace(method))
                items = items.Where(i => i.PaymentMethod.Equals(method, StringComparison.OrdinalIgnoreCase));
            if (!string.IsNullOrWhiteSpace(verification))
                items = items.Where(i => i.VerificationStatus.Equals(verification, StringComparison.OrdinalIgnoreCase));

            return items.ToList();
        }

        public async Task<string> GetProofUrlAsync(Guid paymentId)
        {
            var payment = await _paymentRepository.GetByIdAsync(paymentId)
                ?? throw new KeyNotFoundException($"Payment with ID {paymentId} was not found.");
            if (string.IsNullOrWhiteSpace(payment.ProofOfPayment))
                throw new BusinessRuleException("This payment has no proof of payment.");

            return await _proofStorage.GetSignedUrlAsync(payment.ProofOfPayment, 300);
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

        private static PaymentReviewDto MapToReview(Payment p) => new(
            p.PaymentId, p.OrderId, p.Order.OrderNumber,
            $"{p.Order.Customer.User.FirstName} {p.Order.Customer.User.LastName}",
            p.PaymentType.ToString(), p.PaymentMethod.ToString(),
            p.PaymentStatus.ToString(), p.VerificationStatus.ToString(),
            p.Amount, p.BankReference, p.RejectionReason, p.PaymentDate,
            !string.IsNullOrWhiteSpace(p.ProofOfPayment));
    }
}