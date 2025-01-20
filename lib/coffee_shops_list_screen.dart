import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Add this import for LatLng

class CoffeeShopsListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> coffeeShops;
  final LatLng currentLocation;

  CoffeeShopsListScreen({required this.coffeeShops, required this.currentLocation});

  @override
  _CoffeeShopsListScreenState createState() => _CoffeeShopsListScreenState();
}

class _CoffeeShopsListScreenState extends State<CoffeeShopsListScreen> {
  late List<Map<String, dynamic>> _sortedCoffeeShops;

  @override
  void initState() {
    super.initState();
    _sortedCoffeeShops = List.from(widget.coffeeShops);
  }

  double _calculateDistance(LatLng shopLocation) {
    double distanceInMeters = Geolocator.distanceBetween(
      widget.currentLocation.latitude,
      widget.currentLocation.longitude,
      shopLocation.latitude,
      shopLocation.longitude,
    );
    return distanceInMeters / 1000; // Convert to kilometers
  }

  // Sort by distance (Closest to furthest)
  void _sortByDistanceAsc() {
    setState(() {
      _sortedCoffeeShops.sort((a, b) {
        double distanceA = _calculateDistance(LatLng(a['lat'], a['lng']));
        double distanceB = _calculateDistance(LatLng(b['lat'], b['lng']));
        return distanceA.compareTo(distanceB);
      });
    });
  }

  // Sort by distance (Furthest to closest)
  void _sortByDistanceDesc() {
    setState(() {
      _sortedCoffeeShops.sort((a, b) {
        double distanceA = _calculateDistance(LatLng(a['lat'], a['lng']));
        double distanceB = _calculateDistance(LatLng(b['lat'], b['lng']));
        return distanceB.compareTo(distanceA);
      });
    });
  }

  // Sort by rating (Highest to lowest)
  void _sortByRatingDesc() {
    setState(() {
      _sortedCoffeeShops.sort((a, b) {
        // Convert rating to double
        double ratingA = a['rating'] is double ? a['rating'] : double.tryParse(a['rating'].toString()) ?? 0.0;
        double ratingB = b['rating'] is double ? b['rating'] : double.tryParse(b['rating'].toString()) ?? 0.0;
        return ratingB.compareTo(ratingA); // Highest to lowest
      });
    });
  }

  // Sort by rating (Lowest to highest)
  void _sortByRatingAsc() {
    setState(() {
      _sortedCoffeeShops.sort((a, b) {
        // Convert rating to double
        double ratingA = a['rating'] is double ? a['rating'] : double.tryParse(a['rating'].toString()) ?? 0.0;
        double ratingB = b['rating'] is double ? b['rating'] : double.tryParse(b['rating'].toString()) ?? 0.0;
        return ratingA.compareTo(ratingB); // Lowest to highest
      });
    });
  }

  void _navigateToGoogleMaps(Map<String, dynamic> shop) {
    Navigator.pop(context, shop); // Return to Google Maps and zoom into the selected coffee shop
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coffee Shops List'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'distance_asc') {
                _sortByDistanceAsc();
              } else if (value == 'distance_desc') {
                _sortByDistanceDesc();
              } else if (value == 'rating_asc') {
                _sortByRatingAsc();
              } else if (value == 'rating_desc') {
                _sortByRatingDesc();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'distance_asc',
                  child: Text('Sort by Distance (Closest to Furthest)'),
                ),
                PopupMenuItem<String>(
                  value: 'distance_desc',
                  child: Text('Sort by Distance (Furthest to Closest)'),
                ),
                PopupMenuItem<String>(
                  value: 'rating_asc',
                  child: Text('Sort by Rating (Lowest to Highest)'),
                ),
                PopupMenuItem<String>(
                  value: 'rating_desc',
                  child: Text('Sort by Rating (Highest to Lowest)'),
                ),
              ];
            },
          ),
        ],
      ),
      body: _sortedCoffeeShops.isEmpty
          ? Center(child: Text('No coffee shops found.'))
          : ListView.builder(
              itemCount: _sortedCoffeeShops.length,
              itemBuilder: (context, index) {
                var shop = _sortedCoffeeShops[index];
                double distance = _calculateDistance(
                  LatLng(shop['lat'], shop['lng']),
                );

                return ListTile(
                  title: Text(shop['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rating: ${shop['rating'] ?? 'N/A'}'),
                      Text('Distance: ${distance.toStringAsFixed(2)} km'),
                    ],
                  ),
                  onTap: () {
                    // Navigate back to the GoogleMapsScreen and pass the selected coffee shop data
                    _navigateToGoogleMaps(shop);
                  },
                );
              },
            ),
    );
  }
}
