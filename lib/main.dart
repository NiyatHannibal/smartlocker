import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PinAuthApp());
}

class PinAuthApp extends StatelessWidget {
  const PinAuthApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PIN Authentication',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const PinScreen(),
    );
  }
}

class PinScreen extends StatefulWidget {
  const PinScreen({Key? key}) : super(key: key);

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final String correctPin = "1234"; // Example PIN
  String currentPin = "";
  String message = "";
  Color messageColor = Colors.black;
  BluetoothConnection? connection;

  @override
  void initState() {
    super.initState();
    scanForBluetoothDevice();
  }

  // Discover available Bluetooth devices and connect to a specific device
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

            connection!.input!.listen((data) {
              handleArduinoCommand(utf8.decode(data));
            });
          }).catchError((e) {
            setState(() {
              message = "Error during connection: $e";
              messageColor = Colors.red;
            });
          });
        }
      });
    } catch (e) {
      setState(() {
        message = "Error during Bluetooth discovery: $e";
        messageColor = Colors.red;
      });
    }
  }

  // Handle responses from the Arduino or Bluetooth device
  void handleArduinoCommand(String command) {
    setState(() {
      if (command == 'UNLOCKED') {
        message = "Locker Unlocked!";
        messageColor = Colors.green;
      } else if (command == 'WRONG_PIN') {
        message = "Wrong PIN!";
        messageColor = Colors.red;
      } else if (command == 'LOCKED') {
        message = "Locker is Locked.";
        messageColor = Colors.black;
      } else {
        message = "Unknown Command: $command";
        messageColor = Colors.orange;
      }
    });
  }

  // Send PIN to the Arduino via Bluetooth
  void sendPinToArduino(String pin) async {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(utf8.encode("PIN:$pin\r\n"));
      setState(() {
        message = "PIN sent to Arduino!";
        messageColor = Colors.blue;
      });
    } else {
      setState(() {
        message = "Bluetooth not connected!";
        messageColor = Colors.red;
      });
    }
  }

  void addDigit(String digit) {
    if (currentPin.length < 4) {
      setState(() {
        currentPin += digit;
        message = "";
      });

      if (currentPin.length == 4) {
        sendPinToArduino(currentPin); // Send the PIN to Arduino
        verifyPin();
      }
    }
  }

  void deleteDigit() {
    if (currentPin.isNotEmpty) {
      setState(() {
        currentPin = currentPin.substring(0, currentPin.length - 1);
        message = "";
      });
    }
  }

  void clearPin() {
    setState(() {
      currentPin = "";
      message = "";
    });
  }

  void verifyPin() {
    setState(() {
      FirebaseFirestore.instance.collection('pinLogs').add({
        'pin': currentPin,
        'status': currentPin == correctPin ? 'Correct' : 'Wrong',
        'timestamp': Timestamp.now(),
      });

      if (currentPin != correctPin) {
        FirebaseFirestore.instance.collection('failedPinAttempts').add({
          'pin': currentPin,
          'status': 'Wrong',
          'timestamp': Timestamp.now(),
        });
        message = "Wrong PIN!";
        messageColor = Colors.red;
      } else {
        FirebaseFirestore.instance.collection('successfulPinAttempts').add({
          'pin': currentPin,
          'status': 'Correct',
          'timestamp': Timestamp.now(),
        });
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        currentPin = "";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display the entered PIN (masked)
              Text(
                currentPin.replaceAll(RegExp(r"."), "*"),
                style:
                    const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Message to show the status
              Text(
                message,
                style: TextStyle(color: messageColor, fontSize: 18),
              ),
              const SizedBox(height: 30),
              // Number pad
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  String buttonText;
                  if (index < 9) {
                    buttonText = (index + 1).toString();
                  } else if (index == 9) {
                    buttonText = '0';
                  } else if (index == 10) {
                    buttonText = 'Clear';
                  } else {
                    buttonText = 'Del';
                  }

                  return ElevatedButton(
                    onPressed: () {
                      if (buttonText == 'Clear') {
                        clearPin();
                      } else if (buttonText == 'Del') {
                        deleteDigit();
                      } else {
                        addDigit(buttonText);
                      }
                    },
                    child:
                        Text(buttonText, style: const TextStyle(fontSize: 20)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
