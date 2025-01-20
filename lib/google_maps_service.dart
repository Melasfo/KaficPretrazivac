import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleMapsService {
  final String apiKey = 'AIzaSyBJuNBafiBTshGnCdCopwmO7_uRJvseWuU'; // Replace with your actual API Key
  final String backendBaseUrl = 'https://b7f0-93-139-104-244.ngrok-free.app'; // Backend base URL

  // Fetch the place details (including rating)
  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&fields=name,formatted_address,rating,opening_hours,photos,reviews,geometry&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['result']; // Return the detailed result
    } else {
      throw Exception('Failed to load place details');
    }
  }

  Future<String?> fetchPlaceId(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&fields=place_id&key=$apiKey';

    print('Fetching Place ID from URL: $url'); // Debug: Print the API request URL

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final fetchedPlaceId = data['result']?['place_id'];

      // Debug: Print the entire response and the fetched place_id
      print('API Response: $data');
      print('Fetched Place ID: $fetchedPlaceId');

      return fetchedPlaceId; // Return only the place_id
    } else {
      // Debug: Print the error response
      print('Failed to fetch place_id. Status Code: ${response.statusCode}');
      print('Error Response: ${response.body}');

      throw Exception('Failed to load place_id');
    }
  }

  // Fetch ratings for multiple coffee shops
  Future<void> fetchRatingsForShops(List<Map<String, dynamic>> coffeeShops) async {
    for (int i = 0; i < coffeeShops.length; i++) {
      String placeId = coffeeShops[i]['place_id'];
      var placeDetails = await fetchPlaceDetails(placeId);
      coffeeShops[i]['rating'] = placeDetails['rating'] ?? 'No Rating'; // Add rating or 'No Rating'
    }
  }

  // Fetch nearby coffee shops from the Google Places API
  Future<List<Map<String, dynamic>>> fetchNearbyCoffeeShops(double latitude, double longitude, {int radius = 12000}) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radius&type=cafe&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> places = [];

      for (var place in data['results']) {
        if (place['types'].contains('cafe')) {
          places.add({
            'name': place['name'],
            'lat': place['geometry']['location']['lat'],
            'lng': place['geometry']['location']['lng'],
            'vicinity': place['vicinity'],
            'place_id': place['place_id'], // Store place_id for fetching details later
          });
        }
      }

      // Fetch and add ratings to coffee shops
      await fetchRatingsForShops(places);

      return places;
    } else {
      throw Exception('Failed to load coffee shops');
    }
  }

  // Fetch autocomplete suggestions based on the user's query
  Future<List<dynamic>> fetchAutocompleteSuggestions(String query) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['predictions']; // Return autocomplete predictions
    } else {
      throw Exception('Failed to fetch autocomplete suggestions');
    }
  }

  // Send review to the backend API
  Future<bool> sendReviewToBackend(String firebaseUid, int rating, String comment, String placeId) async {
    final String url = '$backendBaseUrl/user/review'; // Use the backendBaseUrl for the review endpoint

    final reviewDto = {
      'firebaseUid': firebaseUid,
      'rating': rating,
      'comment': comment,
      'placeId': placeId
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reviewDto),
    );

    if (response.statusCode == 200) {
      print('Review added successfully.');
      return true;
    } else {
      print('Failed to add review: ${response.body}');
      return false;
    }
  }

  // Save a coffee shop as a favorite
  Future<bool> saveCoffeeShopAsFavorite(String firebaseUid, String coffeeShopId) async {
    final String url = '$backendBaseUrl/user/save-favorite'; // Use the backendBaseUrl

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebaseUid': firebaseUid,
        'coffeeShopId': coffeeShopId,
      }),
    );

    if (response.statusCode == 200) {
      print('Coffee shop saved to favorites successfully.');
      return true;
    } else {
      print('Failed to save coffee shop to favorites: ${response.body}');
      return false;
    }
  }
  Future<List<String>> fetchFavoriteCoffeeShopPlaceIds(String firebaseUid) async {
  final String url = '$backendBaseUrl/user/favorites/$firebaseUid';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return List<String>.from(data); // Assuming the backend returns a list of place IDs
  } else {
    throw Exception('Failed to fetch favorite coffee shops');
  }
}
}
