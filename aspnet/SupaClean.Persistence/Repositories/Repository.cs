using Microsoft.EntityFrameworkCore;
using SupaClean.Application.Contracts.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Repositories
{
    public class Repository<T> : IRepository<T> where T : class
    {
        protected readonly AppDbContext _db;
        protected readonly DbSet<T> _set;

        public Repository(AppDbContext db)
        {
            _db = db;
            _set = db.Set<T>();
        }

        public virtual async Task<T?> GetByIdAsync(Guid id) => await _set.FindAsync(id);

        public virtual async Task<IEnumerable<T>> GetAllAsync() => await _set.ToListAsync();

        public virtual async Task<T> AddAsync(T entity)
        {
            await _set.AddAsync(entity);
            return entity;
        }

        public virtual Task Update(T entity)
        {
            // Entities loaded through this context are already tracked, so EF sees the
            // changes on its own. Only attach the entity if it came from somewhere else.
            if (_db.Entry(entity).State == EntityState.Detached)
                _set.Update(entity);
            return Task.CompletedTask;
        }

        public virtual Task Delete(T entity)
        {
            _set.Remove(entity);
            return Task.CompletedTask;
        }
    }
}
