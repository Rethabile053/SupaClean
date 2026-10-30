using Microsoft.EntityFrameworkCore;
using SupaClean.Application.Contracts.Repositories;
using SupaClean.Domain.Entities;

namespace SupaClean.Persistence.Repositories
{
    public class DriverRepository : Repository<Driver>, IDriverRepository
    {
        public DriverRepository(AppDbContext db) : base(db) { }

        public async Task<Driver?> GetByUserIdAsync(Guid userId)
            => await _set.Include(d => d.Employee)
                         .FirstOrDefaultAsync(d => d.Employee.UserId == userId);

        public async Task<Driver> GetOrCreateForUserAsync(User user)
        {
            var existing = await GetByUserIdAsync(user.UserId);
            if (existing is not null) return existing;

            // A driver signs in through Supabase, so the Driver row keeps no password
            // of its own and the licence number is not recorded yet.
            var employee = await _db.Employees.FirstOrDefaultAsync(e => e.UserId == user.UserId)
                           ?? new Employee(user.UserId, "Driver");
            if (_db.Entry(employee).State == EntityState.Detached)
                await _db.Employees.AddAsync(employee);

            var driver = new Driver(employee.EmployeeId, password: string.Empty,
                                    email: user.Email, licenseNumber: "Not recorded");
            await _set.AddAsync(driver);
            return driver;
        }
    }
}
