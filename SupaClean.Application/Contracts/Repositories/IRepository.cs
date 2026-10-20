using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Application.Contracts.Repositories
{
    public interface IRepository<T> where T : class
    {
        Task<T?> GetByIdAsync(Guid id);
      
        Task<T> AddAsync(T entity);

        Task<IEnumerable<T>> GetAllAsync();

        Task Update (T entity);

        Task Delete (T  entity);
    }
}
