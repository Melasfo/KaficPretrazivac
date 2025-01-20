using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace KaficPretrazivac.Models
{
    public class Review
    {
        [Key]
        public int Id { get; set; } // Auto-incrementing unique identifier

        [Required]
        public int UserId { get; set; } // Foreign key to User's Id

        [ForeignKey("UserId")]
        public User User { get; set; } // Navigation property

        [Required]
        public int Rating { get; set; } // Rating from 1 to 5

        [Required]
        public string Comment { get; set; } // User's comment on the coffee shop

        [Required]
        public string PlaceId { get; set; } // Google Places PlaceId
    }
}
