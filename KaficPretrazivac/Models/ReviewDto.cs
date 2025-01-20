namespace KaficPretrazivac.Models
{
    public class ReviewDto
    {
        public string FirebaseUid { get; set; } // Firebase UID of the user
        public int Rating { get; set; } // Rating (1 to 5)
        public string Comment { get; set; } // Review comment
        public string PlaceId { get; set; } // Google Places Place ID
    }
}
