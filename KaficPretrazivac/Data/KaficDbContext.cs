using KaficPretrazivac.Models;
using Microsoft.EntityFrameworkCore;

public class KaficDbContext : DbContext
{
    public KaficDbContext(DbContextOptions<KaficDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<FavoriteCoffeeShop> FavoriteCoffeeShops { get; set; }
    public DbSet<Review> Reviews { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // User Configuration
        modelBuilder.Entity<User>()
            .HasKey(u => u.Id);

        modelBuilder.Entity<User>()
            .HasMany(u => u.FavoriteCoffeeShops)
            .WithOne(f => f.User)
            .HasForeignKey(f => f.UserId)
            .OnDelete(DeleteBehavior.Cascade); // User deletion cascades to FavoriteCoffeeShops

        modelBuilder.Entity<User>()
            .HasMany(u => u.Reviews)
            .WithOne(r => r.User)
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade); // User deletion cascades to Reviews

        // FavoriteCoffeeShop Configuration
        modelBuilder.Entity<FavoriteCoffeeShop>()
            .HasKey(f => f.Id);

        modelBuilder.Entity<FavoriteCoffeeShop>()
            .Property(f => f.CoffeeShopId)
            .IsRequired();

        // Review Configuration
        modelBuilder.Entity<Review>()
            .HasKey(r => r.Id);

        modelBuilder.Entity<Review>()
            .Property(r => r.Rating)
            .IsRequired();

        modelBuilder.Entity<Review>()
            .Property(r => r.Comment)
            .IsRequired();

        modelBuilder.Entity<Review>()
            .Property(r => r.PlaceId)
            .IsRequired();
    }
}
