import 'package:flutter/material.dart';
import 'auth_service.dart';

class RegistrationPopup extends StatelessWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  RegistrationPopup({required this.onSuccess, required this.onCancel});

  void _register(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showDialog(context, 'Error', 'Please provide both email and password.');
      return;
    }

    bool success = await _authService.registerUser(email, password);
    if (success) {
      _showDialog(context, 'Success', 'Registration complete!', onClose: () {
        onSuccess();
        Navigator.of(context).pop();
      });
    } else {
      _showDialog(context, 'Error', 'Registration failed. Please try again.');
    }
  }

  void _showDialog(BuildContext context, String title, String message, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onClose != null) onClose();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Register'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            onCancel();
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _register(context),
          child: Text('Register'),
        ),
      ],
    );
  }
}

class LoginPopup extends StatelessWidget {
  final Function(String) onSuccess;
  final VoidCallback onCancel;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  LoginPopup({required this.onSuccess, required this.onCancel});

  void _login(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showDialog(context, 'Error', 'Please provide both email and password.');
      return;
    }

    bool success = await _authService.loginUser(email, password);
    if (success) {
      onSuccess(email); // Pass email as the username
      Navigator.of(context).pop();
    } else {
      _showDialog(context, 'Error', 'Login failed. Please try again.');
    }
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Login'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            onCancel();
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _login(context),
          child: Text('Login'),
        ),
      ],
    );
  }
}
