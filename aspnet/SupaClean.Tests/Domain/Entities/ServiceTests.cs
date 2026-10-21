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
        public void Create_WithValidData_ShouldInitializeCorrectly()
        {
            var service = new Service("Suit Dry Clean", 180.00m, 2, "Full suit cleaning");

            Assert.AreEqual("Suit Dry Clean", service.ServiceName);
            Assert.AreEqual(180.00m, service.Price);
            Assert.AreEqual(2, service.TurnaroundDays);
            Assert.IsTrue(service.IsActive);
        }

        [TestMethod]
        public void Create_WithNegativePrice_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() => new Service("Carpet Clean", -150m, 3));

        [TestMethod]
        public void Create_WithZeroTurnaround_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() => new Service("Carpet Clean", 150m, 0));

        [TestMethod]
        public void UpdatePrice_WithNegativeValue_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() =>
                new Service("Curtain Clean", 120m, 2).UpdatePrice(-10m));

        [TestMethod]
        public void Deactivate_ShouldMarkServiceInactive()
        {
            var service = new Service("Curtain Clean", 120m, 2);
            service.Deactivate();
            Assert.IsFalse(service.IsActive);
        }
    }
}
    

