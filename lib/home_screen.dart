import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'google_maps_screen.dart';
import 'favorite_coffee_shops_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'auth_popups.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  String? _username;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkLoggedInUser();
  }

  Future<void> _checkLoggedInUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _username = currentUser.email; // Use email as the username
      });
    }
  }

  Future<void> _register() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    await showDialog(
      context: context,
      builder: (context) => RegistrationPopup(
        onSuccess: () async {
          setState(() {
            _isProcessing = false;
          });
          _checkLoggedInUser();
        },
        onCancel: () {
          setState(() {
            _isProcessing = false;
          });
        },
      ),
    );
  }

  Future<void> _login() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    await showDialog(
      context: context,
      builder: (context) => LoginPopup(
        onSuccess: (username) async {
          setState(() {
            _username = username;
            _isProcessing = false;
          });
        },
        onCancel: () {
          setState(() {
            _isProcessing = false;
          });
        },
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      setState(() {
        _username = null;
      });
    } catch (e) {
      print('Logout failed: $e');
    }
  }

  Future<void> _checkGPSAndNavigate() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GoogleMapsScreen()),
      );
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Services Disabled'),
        content: Text('Please enable location services to find nearby coffee shops.'),
        actions: [
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Navigator.of(context).pop();
            },
            child: Text('Enable GPS'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kafić Pretraživač')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _checkGPSAndNavigate,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text('Find Coffee Shops'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FavoriteCoffeeShopsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text('My Favorite Coffee Shops'),
            ),
            SizedBox(height: 24),
            if (_username == null) ...[
              ElevatedButton(
                onPressed: _isProcessing ? null : _register,
                child: _isProcessing ? CircularProgressIndicator() : Text('Register'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isProcessing ? null : _login,
                child: _isProcessing ? CircularProgressIndicator() : Text('Login'),
              ),
            ] else ...[
              Text('Welcome, $_username!'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _logout,
                child: Text('Logout'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}