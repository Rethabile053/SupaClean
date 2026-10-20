using SupaClean.Domain.Entities;
using SupaClean.Domain.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Tests.Domain.Entities
{
    [TestClass]
   public class ServiceTests
    {
        [TestMethod]
        public void CreateService_WithValidData_ShouldInitializeCorrectly()
        {
            // Act
            var service = new Service("Suit Dry Clean", 180.00m, "Full suit cleaning");

            // Assert
            Assert.AreEqual("Suit Dry Clean", service.ServiceName);
            Assert.AreEqual(180.00m, service.Price);
           
        }

        [TestMethod]
        public void CreateService_WithNegativePrice_ShouldThrowBusinessRuleException()
        {
            // Act & Assert
            Assert.ThrowsExactly<BusinessRuleException>(() =>
                new Service("Carpet Clean", -150.00m)
            );
        }

        [TestMethod]
        public void UpdatePrice_WithNegativeValue_ShouldThrowBusinessRuleException()
        {
            // Arrange
            var service = new Service("Curtain Clean", 120.00m);

            // Act & Assert
            Assert.ThrowsExactly<BusinessRuleException>(() =>
                service.UpdatePrice(-10.00m)
            );
        }
    }
}
    

