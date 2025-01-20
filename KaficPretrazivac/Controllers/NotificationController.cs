using FirebaseAdmin.Messaging;
using KaficPretrazivac.Models;
using KaficPretrazivac.Services;  // Ensure you import the FirebaseService
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace KaficPretrazivac.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NotificationController : ControllerBase
    {
        // Ensure Firebase is initialized in the constructor or entry point (e.g., in Startup.cs)
        public NotificationController()
        {
            // Initialize Firebase (ensure it's done only once when the app starts)
            FirebaseService.Initialize();
        }

        [HttpPost("send-notification")]
        public async Task<IActionResult> SendNotification([FromBody] NotificationRequest request)
        {
            try
            {
                // Prepare the FCM message data payload
                var dataPayload = new Dictionary<string, string>
                {
                    { "title", request.Title ?? "" },
                    { "body", request.Body ?? "" },
                    { "payload", request.Payload ?? "" },
                    { "imageUrl", request.ImageUrl ?? "" }
                };

                // Add actions to the data payload if any actions exist
                if (request.Actions != null)
                {
                    for (int i = 0; i < request.Actions.Count; i++)
                    {
                        dataPayload.Add($"action_{i}_id", request.Actions[i].ActionId);
                        dataPayload.Add($"action_{i}_title", request.Actions[i].Title);
                    }
                }

                // Create the message with only the 'data' field and nothing else
                var message = new Message
                {
                    Token = request.Token,
                    Data = dataPayload  // Send only the 'data' payload
                };

                // Send the notification using Firebase
                var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);

                // Return success response
                return Ok($"Notification sent successfully: {response}");
            }
            catch (Exception ex)
            {
                // Return an error response if something goes wrong
                return StatusCode(500, $"Failed to send notification: {ex.Message}");
            }
        }
    }
}
