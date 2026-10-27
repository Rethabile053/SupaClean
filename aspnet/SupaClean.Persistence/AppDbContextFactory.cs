using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;


namespace SupaClean.Persistence
{
    
  
        public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
        {
            public AppDbContext CreateDbContext(string[] args)
            {
                var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();

                // This dummy connection string is only used for building/generating the migration files at design-time
                optionsBuilder.UseNpgsql("Host=aws-1-eu-central-1.pooler.supabase.com;Database=postgres;Username=postgres.anuayvbkxntskuuewxae;Password=jYE2LXH1exm0ZGlv");

                return new AppDbContext(optionsBuilder.Options);
            }
        
    }
}
