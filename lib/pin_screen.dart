import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shimmer/shimmer.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({Key? key}) : super(key: key);

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final String correctPin = "1234"; // Example PIN
  String currentPin = "";
  String message = "Enter PIN";
  Color messageColor = Colors.white;
  BluetoothConnection? connection;

  @override
  void initState() {
    super.initState();
    scanForBluetoothDevice();
  }

  void scanForBluetoothDevice() async {
    try {
      FlutterBluetoothSerial.instance.startDiscovery().listen((result) async {
        if (result.device.name == 'YourBluetoothDeviceName') {
          await FlutterBluetoothSerial.instance.cancelDiscovery();
          BluetoothConnection.toAddress(result.device.address).then((conn) {
            connection = conn;
            setState(() {
              message = "Connected to ${result.device.name}";
              messageColor = Colors.green;
            });
          }).catchError((e) {
            setState(() {
              message = "Connection error: $e";
              messageColor = Colors.red;
            });
          });
        }
      });
    } catch (e) {
      setState(() {
        message = "Discovery error: $e";
        messageColor = Colors.red;
      });
    }
  }

  void _onNumberPressed(String number) {
    if (currentPin.length < 4) {
      setState(() {
        currentPin += number;
      });
    }
  }

  void _onBackspacePressed() {
    if (currentPin.isNotEmpty) {
      setState(() {
        currentPin = currentPin.substring(0, currentPin.length - 1);
      });
    }
  }

  void verifyPin() {
    if (currentPin != correctPin) {
      setState(() {
        message = "Wrong PIN!";
        messageColor = Colors.red;
      });
      FirebaseFirestore.instance.collection('failedAttempts').add({
        'pin': currentPin,
        'timestamp': Timestamp.now(),
      });
      setState(() {
        currentPin = ""; // Clear the pin
      });
    } else {
      setState(() {
        message = "Locker Unlocked!";
        messageColor = Colors.green;
        currentPin = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.deepPurple],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Shimmer.fromColors(
                  // Shimmer effect on text
                  baseColor: Colors.white,
                  highlightColor: Colors.grey[200]!,
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        message,
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
                const SizedBox(height: 20),
                Text(
                  currentPin.padRight(4, "*"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberButton('1'),
                        _buildNumberButton('2'),
                        _buildNumberButton('3'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberButton('4'),
                        _buildNumberButton('5'),
                        _buildNumberButton('6'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberButton('7'),
                        _buildNumberButton('8'),
                        _buildNumberButton('9'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBackspaceButton(),
                        _buildNumberButton('0'),
                        _buildSubmitButton(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => _onNumberPressed(number),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: _onBackspacePressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: const Icon(Icons.backspace),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: verifyPin,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.green.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: const Icon(Icons.check),
      ),
    );
  }
}
