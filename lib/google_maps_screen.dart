import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'google_maps_service.dart';
import 'coffee_shops_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleMapsScreen extends StatefulWidget {
  @override
  _GoogleMapsScreenState createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  late double _latitude;
  late double _longitude;
  bool _isLoading = true;
  bool _useUserLocation = true;
  String _loadingMessage = "Fetching your location...";
  List<Map<String, dynamic>> _coffeeShops = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = "Searching for coffee shops around you...";
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('Location permission denied.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    Position position =
        await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });

    await _fetchCoffeeShops();
    _moveCameraToLocation(_latitude, _longitude);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchCoffeeShops() async {
    GoogleMapsService googleMapsService = GoogleMapsService();
    List<Map<String, dynamic>> coffeeShops =
        await googleMapsService.fetchNearbyCoffeeShops(_latitude, _longitude);

    setState(() {
      _coffeeShops = coffeeShops;
      _markers.clear();
      for (var shop in coffeeShops) {
        _markers.add(
          Marker(
            markerId: MarkerId(shop['name']),
            position: LatLng(shop['lat'], shop['lng']),
            infoWindow: InfoWindow(title: shop['name'], snippet: shop['vicinity']),
            onTap: () => _onMarkerTapped(shop['place_id']),
          ),
        );
      }
    });
  }

  void _moveCameraToLocation(double latitude, double longitude) {
    _controller?.animateCamera(
      CameraUpdate.newLatLng(LatLng(latitude, longitude)),
    );
  }

void _onMarkerTapped(String placeId) async {
  GoogleMapsService googleMapsService = GoogleMapsService();
  try {
    var placeDetails = await googleMapsService.fetchPlaceDetails(placeId);

    // Show the details in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(placeDetails['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Address: ${placeDetails['formatted_address']}'),
              if (placeDetails['rating'] != null)
                Text('Rating: ${placeDetails['rating']}'),
              if (placeDetails['opening_hours'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Opening Hours:'),
                    for (var day in placeDetails['opening_hours']['weekday_text'])
                      Text(day),
                  ],
                ),
              if (placeDetails['photos'] != null && placeDetails['photos'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.network(
                    'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${placeDetails['photos'][0]['photo_reference']}&key=${googleMapsService.apiKey}',
                  ),
                ),
              if (placeDetails['reviews'] != null && placeDetails['reviews'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reviews:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...placeDetails['reviews'].map<Widget>((review) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reviewer: ${review['author_name']}'),
                            Text('Rating: ${review['rating']}'),
                            Text('Comment: ${review['text']}'),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              // "Leave a Review" button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    _showReviewDialog(placeId); // Show review dialog when pressed
                  },
                  child: Text('Leave a Review'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Pass only the placeId to _saveAsFavorite
              _saveAsFavorite(placeId);
            },
            child: Text('Save as Favorite'),
          ),
        ],
      ),
    );
  } catch (e) {
    print('Error fetching place details: $e');
  }
}

// Show review dialog to enter rating and comment
void _showReviewDialog(String placeId) {
  final _commentController = TextEditingController();
  double _rating = 1.0; // Default rating

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Leave a Review'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Leave a comment...',
                ),
              ),
              SizedBox(height: 10),
              // Rating Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                        print("Updated Rating: $_rating");
                      });
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          // Submit button
          TextButton(
            onPressed: () async {
              String comment = _commentController.text.trim();

              // Validate if both rating and comment are provided
              if (_rating == 0 || comment.isEmpty) {
                // Show warning if fields are not filled
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please provide both a rating and a comment.'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                // Fetch the current Firebase user UID
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Call sendReviewToBackend method with the fetched Firebase UID
                  bool success = await GoogleMapsService().sendReviewToBackend(
                    user.uid, // Use the current user's Firebase UID
                    _rating.toInt(),
                    comment,
                    placeId,
                  );

                  if (success) {
                    Navigator.of(context).pop(); // Close the dialog after submission
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully reviewed the coffee shop!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // Handle failure case
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit review. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No user is logged in. Please log in first.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Submit Review'),
          ),
        ],
      ),
    ),
  );
}
// Method to save a place as a favorite
void _saveAsFavorite(String placeId) async {
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    _showLoginRegisterDialog();
  } else {
    print('User is logged in: ${currentUser.email}');
    String firebaseUid = currentUser.uid;

    if (placeId.isNotEmpty) {
      print('Saving CoffeeShopId: $placeId');
      bool success = await GoogleMapsService().saveCoffeeShopAsFavorite(firebaseUid, placeId);
      if (success) {
        print('Coffee shop saved to favorites.');
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added as a favorite coffee shop!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Failed to save coffee shop to favorites.');
        // Show failure message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to favorites. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('Error: CoffeeShopId is empty.');
    }
  }
}


// Method to show a login/register dialog with a single button
void _showLoginRegisterDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Not Logged In'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to be logged in to save a coffee shop as your favorite.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            _navigateToMain(); // Navigate to the main screen
          },
          child: Text('Register/Login'),
        ),
      ],
    ),
  );
}

// Method to navigate back to the main.dart screen
void _navigateToMain() {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

  void _toggleLocationMode() async {
    setState(() {
      _useUserLocation = !_useUserLocation;
    });

    if (_useUserLocation) {
      await _getCurrentLocation();
    }
  }

  void _onSearchSelected(
      double latitude, double longitude, String locationName) async {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _useUserLocation = false;
      _isLoading = true;
      _loadingMessage = "Searching for coffee shops at location...";
    });

    await _fetchCoffeeShops();
    _moveCameraToLocation(latitude, longitude);

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Centered on $locationName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coffee Shops'),
        actions: [
          Switch(
            value: _useUserLocation,
            onChanged: (value) => _toggleLocationMode(),
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            activeTrackColor: Colors.greenAccent,
            inactiveTrackColor: Colors.redAccent,
          ),
          if (!_useUserLocation)
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(
                    googleMapsService: GoogleMapsService(),
                    onLocationSelected: _onSearchSelected,
                  ),
                );
              },
            ),
          // New button for navigating to CoffeeShopsListScreen
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              // Navigate to CoffeeShopsListScreen and pass the coffee shop data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoffeeShopsListScreen(
                    coffeeShops: _coffeeShops,
                    currentLocation: LatLng(_latitude, _longitude),
                  ),
                ),
              ).then((selectedShop) {
                if (selectedShop != null) {
                  // After coming back, zoom to the selected shop's position
                  _moveCameraToLocation(selectedShop['lat'], selectedShop['lng']);
                  _controller?.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(selectedShop['lat'], selectedShop['lng']), 15),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    _loadingMessage,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: LatLng(_latitude, _longitude), zoom: 14),
              markers: _markers,
              onMapCreated: (controller) {
                _controller = controller;
              },
            ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<String?> {
  final GoogleMapsService googleMapsService;
  final Function(double latitude, double longitude, String locationName)
      onLocationSelected;

  CustomSearchDelegate(
      {required this.googleMapsService, required this.onLocationSelected});

  @override
  String? get searchFieldLabel => 'Search for a place';

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text('Type a location to search'));
    }

    return FutureBuilder<List<dynamic>>(
      future: googleMapsService.fetchAutocompleteSuggestions(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No suggestions found.'));
        }

        final suggestions = snapshot.data!;
        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            final description = suggestion['description'];

            return ListTile(
              title: Text(description),
              onTap: () async {
                close(context, null);

                try {
                  final placeId = suggestion['place_id'];
                  final placeDetails =
                      await googleMapsService.fetchPlaceDetails(placeId);

                  final lat = placeDetails['geometry']['location']['lat'];
                  final lng = placeDetails['geometry']['location']['lng'];

                  onLocationSelected(lat, lng, description);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error fetching location details: $e')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );
}
