import 'package:animated_text_kit/animated_text_kit.dart'; // For animated text
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // For shimmer effect

import 'bluetooth_connection_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2), // Duration of icon animation
      vsync: this,
    );
    _animation = CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic);
    _animationController.forward();

    // Delay and navigate safely
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => BluetoothConnectionPage()));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToNextScreen, // Call navigation function on tap
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue, Colors.deepPurple], // Gradient background
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                    scale: _animation,
                    child:
                        const Icon(Icons.lock, size: 120, color: Colors.white)),
                const SizedBox(height: 30),
                Shimmer.fromColors(
                  // Shimmer effect on text
                  baseColor: Colors.white,
                  highlightColor: Colors.grey[200]!,
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Smart Locker System',
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    isRepeatingAnimation: false,
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Tap to Continue",
                    style: TextStyle(color: Colors.white, fontSize: 12))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
