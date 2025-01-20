using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace KaficPretrazivac.Models
{
    public class User
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; } // Auto-incrementing primary key
        public string Username { get; set; } // Username provided during registration
        public string FirebaseUid {  get; set; } 

        // Navigation properties
        public ICollection<FavoriteCoffeeShop> FavoriteCoffeeShops { get; set; } = new List<FavoriteCoffeeShop>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
    }
}
