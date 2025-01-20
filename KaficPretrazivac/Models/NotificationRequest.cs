namespace KaficPretrazivac.Models
{
    public class NotificationRequest
    {
        public string Token { get; set; }  // The FCM token from Flutter
        public string Title { get; set; }  // The title of the push notification
        public string Body { get; set; }   // The body/message of the push notification
        public string Payload { get; set; }
        public string? ImageUrl { get; set; }
        public List<NotificationAction>? Actions { get; set; }  // New property for actions
        public class NotificationAction
        {
            public string ActionId { get; set; }  // Unique identifier for the action
            public string Title { get; set; }    // Text to display on the button
        }
    }
}
