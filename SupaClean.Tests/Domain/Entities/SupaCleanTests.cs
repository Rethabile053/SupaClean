using SupaClean.Domain.Entities;
using SupaClean.Domain.Enums;
using SupaClean.Domain.Exceptions;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Tests.Domain.Entities
{
    [TestClass]
    public class OrderTests
    {
        [TestMethod]
       
        public void CreateOrder_WithEmptyCustomerId_ShouldThrowBusinessRuleException()
        {
            
            Assert.ThrowsExactly<BusinessRuleException>(() => new Order(Guid.Empty));
        }
        

        [TestMethod]

        public void AddOrderItem_ShouldRecalculateTotalAmountCorrectly()
        {
            // Arrange
            var customerId = Guid.NewGuid();
            var order = new Order(customerId);
            var serviceId1 = Guid.NewGuid();
            var serviceId2 = Guid.NewGuid();

            // Act: Add 2 x Dry Clean (R150) + 1 x Wash & Iron (R100)
            order.AddOrderItem(serviceId1, quantity: 2, unitPrice: 150.00m);
            order.AddOrderItem(serviceId2, quantity: 1, unitPrice: 100.00m);

            // Assert
            Assert.AreEqual(400.00m, order.TotalAmount);
            Assert.AreEqual(2, order.OrderItems.Count);
        }

        [TestMethod]
        public void LinkPhysicalTicket_WithValidDocket_ShouldSetTicketNumber()
        {
            
            var order = new Order(Guid.NewGuid());
            string validTicket = "T-80921";

           
            order.LinkPhysicalTicket(validTicket);

        
            Assert.AreEqual("T-80921", order.TicketNumber);
        }

        [TestMethod]
        
        public void LinkPhysicalTicket_WithEmptyString_ShouldThrowBusinessRuleException()
        {
           
            var order = new Order(Guid.NewGuid());

          
 
            Assert.ThrowsExactly<BusinessRuleException>(() => order.LinkPhysicalTicket("   "));
        }
        

       
        [TestMethod]
        public void UpdateStatus_ToCompleted_ShouldSetReturnDate()
        {
        
            var order = new Order(Guid.NewGuid());

            
            order.UpdateStatus(OrderStatus.Completed);

          
            Assert.AreEqual(OrderStatus.Completed, order.OrderStatus);
            Assert.IsNotNull(order.ReturnDate);
        }
    }
}
