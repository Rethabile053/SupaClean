using System.Net;
using System.Text;
using Microsoft.Extensions.Configuration;
using SupaClean.Persistence.Auth;

namespace SupaClean.Tests.Application
{
    // The Supabase sign-up call, with a stand-in for the network: nothing here reaches Supabase.
    [TestClass]
    public class DriverSignUpTests
    {
        private const string FakeKey = "anon-key-for-tests-only";

        private sealed class StubHandler : HttpMessageHandler
        {
            public List<string> Paths { get; } = new();
            public List<string> Bodies { get; } = new();
            public HttpStatusCode SignInStatus { get; set; } = HttpStatusCode.BadRequest;
            public string SignInBody { get; set; } = "{\"error\":\"invalid_grant\"}";
            public HttpStatusCode SignUpStatus { get; set; } = HttpStatusCode.OK;
            public string SignUpBody { get; set; } = "{}";
            public bool Throw { get; set; }

            protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
            {
                if (Throw) throw new HttpRequestException("offline");
                Paths.Add(request.RequestUri!.AbsolutePath);
                Bodies.Add(request.Content is null ? string.Empty : await request.Content.ReadAsStringAsync(cancellationToken));
                Assert.IsTrue(request.Headers.Contains("apikey"));
                Assert.IsNull(request.Headers.Authorization, "only the public key is sent, never a bearer token");

                var signIn = request.RequestUri.AbsolutePath.EndsWith("/token");
                return new HttpResponseMessage(signIn ? SignInStatus : SignUpStatus)
                {
                    Content = new StringContent(signIn ? SignInBody : SignUpBody, Encoding.UTF8, "application/json"),
                };
            }
        }

        private static (SupabaseDriverSignUp SignUp, StubHandler Handler) Create(bool configured = true)
        {
            var settings = new Dictionary<string, string?>();
            if (configured)
            {
                settings["Supabase:Url"] = "https://example.supabase.co/";
                settings["Supabase:AnonKey"] = FakeKey;
            }
            var config = new ConfigurationBuilder().AddInMemoryCollection(settings).Build();
            var handler = new StubHandler();
            return (new SupabaseDriverSignUp(new HttpClient(handler), config), handler);
        }

        [TestMethod]
        public async Task SignUp_ShouldReturnTheNewId_WhenConfirmationIsOn()
        {
            var (signUp, handler) = Create();
            var id = Guid.NewGuid();
            handler.SignUpBody = $"{{\"id\":\"{id}\",\"identities\":[{{\"id\":\"x\"}}]}}";

            var result = await signUp.SignUpAsync("s@x.com", "longenough1", "Sipho Dlamini", "082");

            Assert.IsTrue(result.Success);
            Assert.AreEqual(id, result.UserId);
            CollectionAssert.AreEqual(new[] { "/auth/v1/token", "/auth/v1/signup" }, handler.Paths);
            StringAssert.Contains(handler.Bodies[1], "Sipho Dlamini");
        }

        [TestMethod]
        public async Task SignUp_ShouldReturnTheNewId_WhenConfirmationIsOff()
        {
            var (signUp, handler) = Create();
            var id = Guid.NewGuid();
            handler.SignUpBody = $"{{\"access_token\":\"t\",\"user\":{{\"id\":\"{id}\",\"identities\":[{{\"id\":\"x\"}}]}}}}";

            var result = await signUp.SignUpAsync("s@x.com", "longenough1", "Sipho Dlamini", null);

            Assert.AreEqual(id, result.UserId);
        }

        [TestMethod]
        public async Task SignUp_ShouldReuseAnExistingAccount_WhenThePasswordMatches()
        {
            var (signUp, handler) = Create();
            var id = Guid.NewGuid();
            handler.SignInStatus = HttpStatusCode.OK;
            handler.SignInBody = $"{{\"access_token\":\"t\",\"user\":{{\"id\":\"{id}\"}}}}";

            var result = await signUp.SignUpAsync("s@x.com", "longenough1", "Sipho Dlamini", null);

            Assert.AreEqual(id, result.UserId);
            CollectionAssert.AreEqual(new[] { "/auth/v1/token" }, handler.Paths, "no second account is created");
        }

        [TestMethod]
        public async Task SignUp_ShouldRefuseAnEmailThatIsTakenWithAnotherPassword()
        {
            var (signUp, handler) = Create();
            handler.SignUpBody = $"{{\"id\":\"{Guid.NewGuid()}\",\"identities\":[]}}";

            var result = await signUp.SignUpAsync("s@x.com", "longenough1", "Sipho Dlamini", null);

            Assert.IsFalse(result.Success);
            StringAssert.Contains(result.Error, "already has an account");
        }

        [TestMethod]
        public async Task SignUp_ShouldExplainSupabaseErrorsInPlainWords()
        {
            var (signUp, handler) = Create();
            handler.SignUpStatus = HttpStatusCode.UnprocessableEntity;
            handler.SignUpBody = "{\"msg\":\"User already registered\"}";

            var result = await signUp.SignUpAsync("s@x.com", "longenough1", "Sipho Dlamini", null);

            Assert.IsFalse(result.Success);
            StringAssert.Contains(result.Error, "already has an account");
        }

        [TestMethod]
        public async Task SignUp_ShouldFailPolitely_WhenSupabaseCannotBeReached()
        {
            var (signUp, handler) = Create();
            handler.Throw = true;

            var result = await signUp.SignUpAsync("s@x.com", "longenough1", "Sipho Dlamini", null);

            Assert.IsFalse(result.Success);
            StringAssert.Contains(result.Error, "Could not reach");
        }

        [TestMethod]
        public async Task SignUp_ShouldSaySoWhenTheSettingsAreMissing_WithoutSendingAnything()
        {
            var (signUp, handler) = Create(configured: false);

            var result = await signUp.SignUpAsync("s@x.com", "longenough1", "Sipho Dlamini", null);

            Assert.IsFalse(result.Success);
            Assert.AreEqual(0, handler.Paths.Count);
        }

        [TestMethod]
        public async Task SignUp_ShouldNeverPutTheKeyOrPasswordInAnError()
        {
            var (signUp, handler) = Create();
            handler.SignUpStatus = HttpStatusCode.Unauthorized;
            handler.SignUpBody = $"{{\"msg\":\"bad key {FakeKey} and longenough1\"}}";

            var result = await signUp.SignUpAsync("s@x.com", "longenough1", "Sipho Dlamini", null);

            Assert.IsFalse(result.Success);
            Assert.IsFalse(result.Error!.Contains(FakeKey));
            Assert.IsFalse(result.Error.Contains("longenough1"));
        }
    }
}
