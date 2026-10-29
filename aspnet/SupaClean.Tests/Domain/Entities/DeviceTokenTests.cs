using SupaClean.Domain.Entities;
using SupaClean.Domain.Exceptions;

namespace SupaClean.Tests.Domain.Entities
{
    [TestClass]
    public class DeviceTokenTests
    {
        private static readonly Guid Customer = Guid.NewGuid();

        [TestMethod]
        public void NewDeviceToken_ShouldKeepTheCustomerTokenAndPlatform()
        {
            var device = new DeviceToken(Customer, "  abc123  ", " Android ");

            Assert.AreEqual(Customer, device.CustomerId);
            Assert.AreEqual("abc123", device.Token);
            Assert.AreEqual("android", device.Platform);
            Assert.AreNotEqual(Guid.Empty, device.DeviceTokenId);
        }

        [TestMethod]
        public void NewDeviceToken_WithoutAPlatform_ShouldBeUnknown()
            => Assert.AreEqual("unknown", new DeviceToken(Customer, "abc", null).Platform);

        [TestMethod]
        public void NewDeviceToken_WithABlankToken_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() => new DeviceToken(Customer, "   ", "android"));

        [TestMethod]
        public void NewDeviceToken_WithATokenThatIsTooLong_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(
                () => new DeviceToken(Customer, new string('x', DeviceToken.MaxTokenLength + 1), "android"));

        [TestMethod]
        public void NewDeviceToken_WithoutACustomer_ShouldThrow()
            => Assert.ThrowsExactly<BusinessRuleException>(() => new DeviceToken(Guid.Empty, "abc", "android"));

        [TestMethod]
        public void NewDeviceToken_WithALongPlatform_ShouldBeShortened()
        {
            var device = new DeviceToken(Customer, "abc", new string('p', 50));
            Assert.AreEqual(DeviceToken.MaxPlatformLength, device.Platform.Length);
        }

        [TestMethod]
        public void AssignTo_ShouldMoveThePhoneToTheNewCustomer()
        {
            var device = new DeviceToken(Customer, "abc", "android");
            var other = Guid.NewGuid();

            device.AssignTo(other, "web");

            Assert.AreEqual(other, device.CustomerId);
            Assert.AreEqual("web", device.Platform);
        }
    }
}
