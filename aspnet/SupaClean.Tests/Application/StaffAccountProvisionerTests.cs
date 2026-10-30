using System.Net;
using System.Text;
using Microsoft.Extensions.Configuration;
using SupaClean.Persistence.Auth;

namespace SupaClean.Tests.Application
{
    // The Supabase call, with a stand-in for the network: nothing here reaches Supabase.
    [TestClass]
    public class StaffAccountProvisionerTests
    {
        private const string FakeKey = "service-key-for-tests-only";

        private sealed class StubHandler : HttpMessageHandler
        {
            public List<HttpRequestMessage> Requests { get; } = new();
            public List<string> Bodies { get; } = new();
            public HttpStatusCode Status { get; set; } = HttpStatusCode.OK;
            public string Body { get; set; } = "{}";
            public bool Throw { get; set; }

            protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
            {
                if (Throw) throw new HttpRequestException("offline");
                Requests.Add(request);
                Bodies.Add(request.Content is null ? string.Empty : await request.Content.ReadAsStringAsync(cancellationToken));
                return new HttpResponseMessage(Status) { Content = new StringContent(Body, Encoding.UTF8, "application/json") };
            }
        }

        private static (SupabaseStaffAccountProvisioner Provisioner, StubHandler Handler) Create(bool configured = true)
        {
            var settings = new Dictionary<string, string?>();
            if (configured)
            {
                settings["Supabase:Url"] = "https://example.supabase.co/";
                settings["Supabase:ServiceRoleKey"] = FakeKey;
            }
            var config = new ConfigurationBuilder().AddInMemoryCollection(settings).Build();
            var handler = new StubHandler();
            return (new SupabaseStaffAccountProvisioner(new HttpClient(handler), config), handler);
        }

        [TestMethod]
        public async Task Create_ShouldAskSupabaseForAConfirmedAccount_AndReturnItsId()
        {
            var (provisioner, handler) = Create();
            var id = Guid.NewGuid();
            handler.Body = $"{{\"id\":\"{id}\",\"email\":\"sipho@example.com\"}}";

            var result = await provisioner.CreateAsync("sipho@example.com", "Abcd2345wxyz", "Sipho Dlamini", "0821234567");

            Assert.AreEqual(id, result.UserId);
            Assert.IsNull(result.Error);

            var request = handler.Requests.Single();
            Assert.AreEqual(HttpMethod.Post, request.Method);
            Assert.AreEqual("https://example.supabase.co/auth/v1/admin/users", request.RequestUri!.ToString());
            Assert.AreEqual(FakeKey, request.Headers.GetValues("apikey").Single());
            Assert.AreEqual($"Bearer {FakeKey}", request.Headers.Authorization!.ToString());

            var body = handler.Bodies.Single();
            StringAssert.Contains(body, "\"email_confirm\":true");   // can sign in straight away
            StringAssert.Contains(body, "Sipho Dlamini");
        }

        [TestMethod]
        public async Task Create_WhenTheEmailExists_ShouldSayThatInPlainWords()
        {
            var (provisioner, handler) = Create();
            handler.Status = HttpStatusCode.UnprocessableEntity;
            handler.Body = "{\"msg\":\"A user with this email address has already been registered\"}";

            var result = await provisioner.CreateAsync("a@b.co", "Abcd2345wxyz", "A B", null);

            Assert.IsNull(result.UserId);
            Assert.AreEqual("A login account with that email already exists.", result.Error);
        }

        [TestMethod]
        public async Task Create_WithABadKey_ShouldSayTheKeyIsNotValid_WithoutShowingIt()
        {
            var (provisioner, handler) = Create();
            handler.Status = HttpStatusCode.Unauthorized;
            handler.Body = $"{{\"message\":\"Invalid API key {FakeKey}\"}}";

            var result = await provisioner.CreateAsync("a@b.co", "Abcd2345wxyz", "A B", null);

            StringAssert.Contains(result.Error, "service key");
            Assert.IsFalse(result.Error!.Contains(FakeKey), "the key must never appear in a message");
        }

        [TestMethod]
        public async Task Create_WhenSupabaseCannotBeReached_ShouldSayToTryAgain()
        {
            var (provisioner, handler) = Create();
            handler.Throw = true;

            var result = await provisioner.CreateAsync("a@b.co", "Abcd2345wxyz", "A B", null);

            Assert.IsNull(result.UserId);
            StringAssert.Contains(result.Error, "Could not reach Supabase");
        }

        [TestMethod]
        public async Task Create_WithoutSettings_ShouldSaySoAndSendNothing()
        {
            var (provisioner, handler) = Create(configured: false);

            var result = await provisioner.CreateAsync("a@b.co", "Abcd2345wxyz", "A B", null);

            StringAssert.Contains(result.Error, "not set up");
            Assert.AreEqual(0, handler.Requests.Count);
        }

        [TestMethod]
        public async Task Delete_ShouldRemoveTheAccount()
        {
            var (provisioner, handler) = Create();
            var id = Guid.NewGuid();

            await provisioner.DeleteAsync(id);

            var request = handler.Requests.Single();
            Assert.AreEqual(HttpMethod.Delete, request.Method);
            Assert.AreEqual($"https://example.supabase.co/auth/v1/admin/users/{id}", request.RequestUri!.ToString());
        }
    }
}
