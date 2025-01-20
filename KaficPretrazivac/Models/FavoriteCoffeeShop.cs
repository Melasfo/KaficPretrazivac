using System.ComponentModel.DataAnnotations;

namespace KaficPretrazivac.Models
{
    public class FavoriteCoffeeShop
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }  // Foreign key to User
        public User User { get; set; }   // Navigation property for User
        public string CoffeeShopId { get; set; }  // Foreign key to CoffeeShop (only store the identifier)
    }
}
