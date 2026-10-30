using Microsoft.AspNetCore.Components;
using Microsoft.Extensions.DependencyInjection;

namespace SupaClean.Blazor.Components.Layout
{
    /// <summary>
    /// Base for admin and driver pages that run interactively.
    ///
    /// An interactive page lives as long as the browser tab is open. If it kept
    /// one database connection for all that time, Refresh and Search would keep
    /// showing what was loaded first and miss changes made elsewhere (a customer
    /// cancelling in the app, another admin saving). So a page asks for its
    /// services through <see cref="Svc{T}"/> and starts a <see cref="FreshScope"/>
    /// at the start of each load or save, which gives it a new connection.
    /// </summary>
    public abstract class ScopedPageBase : ComponentBase, IDisposable
    {
        [Inject] private IServiceScopeFactory ScopeFactory { get; set; } = default!;

        private IServiceScope? _scope;

        /// <summary>A service from the current scope.</summary>
        protected T Svc<T>() where T : notnull
            => (_scope ??= ScopeFactory.CreateScope()).ServiceProvider.GetRequiredService<T>();

        /// <summary>
        /// Start using a new scope, so the next call gets fresh data. The old one
        /// is not disposed straight away: a click a moment earlier may still be
        /// reading from it, and closing its connection under it would make that
        /// action fail. It is disposed a minute later.
        /// </summary>
        protected void FreshScope()
        {
            var old = _scope;
            _scope = null;
            if (old is not null)
                _ = DisposeLaterAsync(old);
        }

        private static async Task DisposeLaterAsync(IServiceScope scope)
        {
            try { await Task.Delay(TimeSpan.FromMinutes(1)); } catch { }
            try { scope.Dispose(); } catch { }
        }

        public void Dispose()
        {
            _scope?.Dispose();
            _scope = null;
            GC.SuppressFinalize(this);
        }
    }
}
