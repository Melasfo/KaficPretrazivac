import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final String _backendBaseUrl = 'https://b7f0-93-139-104-244.ngrok-free.app'; // Update your URL here.

  Future<bool> registerUser(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user?.uid;
      if (userId != null) {
        // Send the correct data (firebaseUid and username)
        final response = await http.post(
          Uri.parse('$_backendBaseUrl/user/choose-username'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'firebaseUid': userId,  // Use 'firebaseUid' instead of 'id'
            'username': email,       // 'username' is fine as is
          }),
        );

        if (response.statusCode == 200) {
          print('User registered successfully in backend.');
          return true;
        } else {
          print('Backend registration failed: ${response.body}');
        }
      }
    } catch (e) {
      print('Firebase registration failed: $e');
    }
    return false;
  }

  Future<bool> loginUser(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Login successful for email: $email');
      return true;
    } catch (e) {
      print('Login failed: $e');
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      print('User logged out successfully.');
    } catch (e) {
      print('Logout failed: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  Future<String?> fetchUsername() async {
    try {
      final userId = _firebaseAuth.currentUser?.uid;

      if (userId != null) {
        print('UID sent to backend: $userId'); // Debugging print

        // Corrected GET request with Firebase UID as query parameter
        final response = await http.get(
          Uri.parse('$_backendBaseUrl/user/get-username?firebaseUid=$userId'),
          headers: {'ngrok-skip-browser-warning': '*'}, // ngrok workaround
        );

        print('Response from backend: ${response.body}'); // Debugging print

        if (response.statusCode == 200) {
          // Parse the JSON response and extract the 'username'
          final data = jsonDecode(response.body);
          final username = data['username']; // Get the value of 'username' from the JSON object
          print('Fetched username: $username'); // Debugging print
          return username;
        } else {
          print('Failed to fetch username from backend: ${response.body}');
        }
      } else {
        print('No logged-in user.');
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
    return null;
  }
}
