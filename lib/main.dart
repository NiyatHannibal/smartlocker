import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'bluetooth_connection_page.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PinAuthApp());
}

class PinAuthApp extends StatelessWidget {
  const PinAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Locker System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/', // Splash screen as the initial route
      routes: {
        '/': (context) => SplashScreen(), // Splash Screen
        '/bluetooth': (context) =>
            BluetoothConnectionPage(), // Bluetooth connection page
      },
    );
  }
}
