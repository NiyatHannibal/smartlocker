import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'pin_screen.dart';

class LockUnlockPage extends StatefulWidget {
  final BluetoothConnection connection;
  final String deviceName;

  const LockUnlockPage(
      {super.key, required this.connection, required this.deviceName});

  @override
  _LockUnlockPageState createState() => _LockUnlockPageState();
}

class _LockUnlockPageState extends State<LockUnlockPage> {
  String message = "Locker is locked";
  Color messageColor = Colors.white;
  late BluetoothConnection connection;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    connection = widget.connection;
    _subscribeToDataStream();
  }

  @override
  void dispose() {
    connection.dispose();
    super.dispose();
  }

  void _subscribeToDataStream() {
    connection.input?.listen((Uint8List data) {
      String receivedMessage = String.fromCharCodes(data).trim();
      setState(() {
        message = receivedMessage;
      });
    }).onError((error) {
      setState(() {
        message = "Error receiving data: $error";
        messageColor = Colors.red;
      });
    });
  }

  Future<void> _sendData(String command) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      message = "Sending command..."; //Feedback for sending action
      messageColor = Colors.yellow;
    });

    try {
      if (connection.isConnected) {
        connection.output.add(Uint8List.fromList(utf8.encode(command + "\n")));
        await connection.output.allSent;
        setState(() {
          message =
              "Command Sent: $command"; // Feedback of sent command, wait for response from device.
          messageColor = Colors.blue;
        });
      } else {
        setState(() {
          message = "Connection lost. Please reconnect.";
          messageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        message = "Error sending data: $e";
        messageColor = Colors.red;
      });
    } finally {
      setState(() {
        _isSending = false;
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
                Text(
                  message,
                  style: TextStyle(color: messageColor, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSending
                      ? null
                      : () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PinScreen(
                                connection: connection,
                              ),
                            ),
                          );
                          if (result == true) {
                            setState(() {
                              message = "Locker Unlocked";
                              messageColor = Colors.green;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('Open Locker'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
