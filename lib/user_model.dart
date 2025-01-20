// user_model.dart

class UserModel {
  final String id; // The unique ID from Firebase
  final String username; // Username provided during registration
  List<String> favoriteCoffeeShops; // List to store favorite coffee shop IDs
  List<Map<String, dynamic>> ratings; // List to store ratings for coffee shops
  List<Map<String, dynamic>> comments; // List to store comments for coffee shops

  UserModel({
    required this.id,
    required this.username,
    this.favoriteCoffeeShops = const [],
    this.ratings = const [],
    this.comments = const [],
  });

  // Convert a UserModel to a map (useful for saving to a database in the future)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'favoriteCoffeeShops': favoriteCoffeeShops,
      'ratings': ratings,
      'comments': comments,
    };
  }

  // Create a UserModel from a map (useful for retrieving data from a database)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      favoriteCoffeeShops: List<String>.from(map['favoriteCoffeeShops'] ?? []),
      ratings: List<Map<String, dynamic>>.from(map['ratings'] ?? []),
      comments: List<Map<String, dynamic>>.from(map['comments'] ?? []),
    );
  }
}
