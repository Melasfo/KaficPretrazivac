import 'package:flutter/material.dart';

class CustomBackground extends StatelessWidget {
  final Widget child;

  const CustomBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightBlue.shade50, Colors.white], // Light blue and white gradient
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: child,
      ),
    );
  }
}

class HeaderWithAnimation extends StatefulWidget {
  final String title;

  const HeaderWithAnimation({required this.title});

  @override
  _HeaderWithAnimationState createState() => _HeaderWithAnimationState();
}

class _HeaderWithAnimationState extends State<HeaderWithAnimation> {
  late final List<Color> _gradientColors;
  int _currentColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _gradientColors = [Colors.lightBlue.shade100, Colors.white]; // Updated to match light blue and white theme
    _animateGradient();
  }

  void _animateGradient() {
    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        _currentColorIndex = (_currentColorIndex + 1) % _gradientColors.length;
      });
      _animateGradient();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(seconds: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gradientColors[_currentColorIndex],
            _gradientColors[(_currentColorIndex + 1) % _gradientColors.length]
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16), // Add spacing at the top
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Changed to dark for better contrast
            ),
          ),
        ],
      ),
    );
  }
}

class DesignButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSmall;

  const DesignButton({required this.text, required this.onPressed, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: isSmall
            ? EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0)
            : EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
        textStyle: TextStyle(
          fontSize: isSmall ? 16 : 18,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.lightBlueAccent, // Light blue button
        foregroundColor: Colors.white, // White text on the button
      ),
      child: Text(text),
    );
  }
}
