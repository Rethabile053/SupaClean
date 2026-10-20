using SupaClean.Application.Contracts.Repositories;
using Microsoft.EntityFrameworkCore;
using SupaClean.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SupaClean.Persistence.Repositories
{
    public class CustomerRepository : Repository<Customer>, ICustomerRepository
{
    public CustomerRepository(AppDbContext db) : base(db) { }

    public override async Task<Customer?> GetByIdAsync(Guid id)
        => await _set.Include(c => c.User).FirstOrDefaultAsync(c => c.CustomerId == id);

    public override async Task<IEnumerable<Customer>> GetAllAsync()
        => await _set.Include(c => c.User).ToListAsync();

    public async Task<Customer?> GetByEmailAsync(string email)
        => await _set.Include(c => c.User)
            .FirstOrDefaultAsync(c => c.User.Email == email.Trim().ToLowerInvariant());

    public async Task<Customer?> GetByPhoneNumberAsync(string phoneNumber)
        => await _set.Include(c => c.User)
            .FirstOrDefaultAsync(c => c.User.PhoneNumber == phoneNumber);
    
    }
}
