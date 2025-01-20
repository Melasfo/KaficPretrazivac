using Google.Apis.Auth.OAuth2;
using FirebaseAdmin;
using System;

namespace KaficPretrazivac.Services
{
    public class FirebaseService
    {
        // Initialize Firebase Admin SDK
        private static bool isInitialized = false;

        // Method to initialize Firebase
        public static void Initialize()
        {
            if (!isInitialized)
            {
                try
                {
                    // Initialize FirebaseApp only if it hasn't been initialized yet
                    FirebaseApp.Create(new AppOptions()
                    {
                        Credential = GoogleCredential.FromFile(@"C:\Users\Pefan\Downloads\kafic-pretrazivac-firebase-adminsdk-bo3ig-61890ef68b.json"),
                    });

                    isInitialized = true;
                    Console.WriteLine("Firebase initialized successfully.");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error initializing Firebase: {ex.Message}");
                }
            }
            else
            {
                Console.WriteLine("Firebase app already initialized.");
            }
        }
    }
}
