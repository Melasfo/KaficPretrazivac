using FirebaseAdmin.Messaging;
using KaficPretrazivac.Models;
using KaficPretrazivac.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System;
using System.Linq;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;

namespace KaficPretrazivac.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly KaficDbContext _context;

        public UserController(KaficDbContext context)
        {
            _context = context;
        }

        // Endpoint: Choose a username
        [HttpPost("choose-username")]
        public async Task<IActionResult> ChooseUsername([FromBody] UserCreationDto dto)
        {
            var rawBody = await new StreamReader(Request.Body).ReadToEndAsync();
            Console.WriteLine($"Raw request body: {rawBody}");
            Console.WriteLine($"Received username: {dto.Username}, Firebase UID: {dto.FirebaseUid}");

            if (dto == null || string.IsNullOrEmpty(dto.Username) || string.IsNullOrEmpty(dto.FirebaseUid))
            {
                return BadRequest("Username and Firebase UID are required.");
            }

            // Check if the username already exists
            if (await _context.Users.AnyAsync(u => u.Username == dto.Username))
            {
                return Conflict("Username already exists.");
            }

            // Create a new user with the Firebase UID
            var user = new User
            {
                Username = dto.Username,
                FirebaseUid = dto.FirebaseUid,  // Save the Firebase UID
                FavoriteCoffeeShops = new List<FavoriteCoffeeShop>(), // Initialize empty list
                Reviews = new List<Review>(),                       // Initialize empty list
            };

            try
            {
                _context.Users.Add(user);  // Add the user to the Users collection
                await _context.SaveChangesAsync(); // Save changes to the database

                // Return a response with the user ID for further interactions (if needed)
                return Ok(new { UserId = user.Id, Message = "Username successfully registered." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Failed to save user: {ex.Message}");
            }
        }

        [HttpGet("get-username")]
        public async Task<IActionResult> GetUsername([FromQuery] string firebaseUid)
        {
            Console.WriteLine($"Received Firebase UID: {firebaseUid}"); // Debugging

            if (string.IsNullOrEmpty(firebaseUid))
            {
                return BadRequest("Firebase UID is required.");
            }

            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid);

                if (user == null)
                {
                    return NotFound("User not found.");
                }

                if (string.IsNullOrEmpty(user.Username))
                {
                    return StatusCode(500, "Username is empty for the user.");
                }

                var response = new UsernameResponse
                {
                    Username = user.Username
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error retrieving username: {ex.Message}");
            }
        }
        [HttpPost("save-favorite")]
        public async Task<IActionResult> SaveFavoriteCoffeeShop([FromBody] SaveFavoriteDto dto)
        {
            if (dto == null || string.IsNullOrEmpty(dto.FirebaseUid) || string.IsNullOrEmpty(dto.CoffeeShopId) )
            {
                return BadRequest("Firebase UID and Coffee Shop ID are required.");
            }

            try
            {
                // Find the user by Firebase UID
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.FirebaseUid == dto.FirebaseUid);

                if (user == null)
                {
                    return NotFound("User not found.");
                }

                // Check if the user already has this coffee shop in their favorites
                var existingFavorite = await _context.FavoriteCoffeeShops
                    .FirstOrDefaultAsync(f => f.UserId == user.Id && f.CoffeeShopId == dto.CoffeeShopId);

                if (existingFavorite != null)
                {
                    return Conflict("This coffee shop is already in your favorites.");
                }

                // Add the coffee shop to the user's favorites
                var favoriteCoffeeShop = new FavoriteCoffeeShop
                {
                    UserId = user.Id,
                    CoffeeShopId = dto.CoffeeShopId
                };

                _context.FavoriteCoffeeShops.Add(favoriteCoffeeShop);
                await _context.SaveChangesAsync();

                return Ok(new { Message = "Coffee shop added to favorites." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Failed to save favorite: {ex.Message}");
            }
        }
        [HttpPost("review")]
        public async Task<ActionResult> AddReview([FromBody] ReviewDto reviewDto)
        {
            if (reviewDto == null)
            {
                return BadRequest("Review data is required.");
            }

            // Find the user by Firebase UID
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.FirebaseUid == reviewDto.FirebaseUid);

            if (user == null)
            {
                return NotFound("User not found.");
            }

            // Create the new Review object
            var review = new Review
            {
                UserId = user.Id,
                Rating = reviewDto.Rating,
                Comment = reviewDto.Comment,
                PlaceId = reviewDto.PlaceId
            };

            // Add the review to the database
            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            // Return a success response
            return Ok(new { Message = "Review added successfully" });
        }
        [HttpPost("send-notification")]
        public async Task<IActionResult> SendNotification([FromBody] NotificationRequest request)
        {
            try
            {
                // Prepare the FCM message payload
                var message = new Message
                {
                    Token = request.Token,
                    Notification = new Notification
                    {
                        Title = request.Title,
                        Body = request.Body
                    },
                    Data = new Dictionary<string, string>
                {
                    { "payload", request.Payload ?? "" },
                    { "imageUrl", request.ImageUrl ?? "" }
                }
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
