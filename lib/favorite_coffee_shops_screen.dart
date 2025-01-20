import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'google_maps_service.dart';

class FavoriteCoffeeShopsScreen extends StatefulWidget {
  @override
  _FavoriteCoffeeShopsScreenState createState() =>
      _FavoriteCoffeeShopsScreenState();
}

class _FavoriteCoffeeShopsScreenState extends State<FavoriteCoffeeShopsScreen> {
  List<Map<String, dynamic>> favoritePlaces = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteCoffeeShops();
  }

  Future<void> _fetchFavoriteCoffeeShops() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        String firebaseUid = currentUser.uid;
        List<String> placeIds = await GoogleMapsService()
            .fetchFavoriteCoffeeShopPlaceIds(firebaseUid);

        // Fetch details for each Place ID
        for (String placeId in placeIds) {
          Map<String, dynamic> placeDetails =
              await GoogleMapsService().fetchPlaceDetails(placeId);
          favoritePlaces.add(placeDetails);
        }
      } catch (e) {
        print('Error fetching favorite coffee shops: $e');
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('My Favorite Coffee Shops')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('My Favorite Coffee Shops')),
      body: ListView.builder(
        itemCount: favoritePlaces.length,
        itemBuilder: (context, index) {
          final place = favoritePlaces[index];
          return ListTile(
            title: Text(place['name']),
            subtitle: Text(place['formatted_address']),
            onTap: () {
              _showPlaceDetailsDialog(place);
            },
          );
        },
      ),
    );
  }

  void _showPlaceDetailsDialog(Map<String, dynamic> placeDetails) {
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
                    'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${placeDetails['photos'][0]['photo_reference']}&key=${GoogleMapsService().apiKey}',
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
