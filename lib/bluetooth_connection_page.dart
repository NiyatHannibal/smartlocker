import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'lock_unlock_page.dart';

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({super.key});

  @override
  _BluetoothConnectionPageState createState() =>
      _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage>
    with SingleTickerProviderStateMixin {
  BluetoothConnection? connection;
  String message = 'Tap the Bluetooth icon to start';
  Color messageColor = Colors.white;
  bool _isConnecting = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<BluetoothDevice> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.repeat(reverse: true);
    _checkBluetoothEnabled();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothEnabled() async {
    try {
      bool isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (!isEnabled) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }
    } catch (e) {
      setState(() {
        message = "Error during Bluetooth check: $e";
        messageColor = Colors.red;
      });
    }
  }

  Future<List<BluetoothDevice>> _startDiscovery() async {
    setState(() {
      message = 'Scanning for devices...';
      _isConnecting = true;
      _availableDevices = [];
    });

    try {
      List<BluetoothDevice> devices = [];
      await FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        if (!devices
            .any((element) => element.address == result.device.address)) {
          devices.add(result.device);
          setState(() {
            message = 'Found ${result.device.name}';
          });
        }
      }).asFuture();
      return devices;
    } catch (e) {
      setState(() {
        message = "Error during Bluetooth discovery: $e";
        messageColor = Colors.red;
        _isConnecting = false;
      });
      return [];
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _showAvailableDevices() async {
    List<BluetoothDevice> devices = await _startDiscovery();

    setState(() {
      _availableDevices = devices;
      if (_availableDevices.isEmpty) {
        message = "No devices found. Please try again.";
        messageColor = Colors.red;
      } else {
        message = "Please select a device to connect to";
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      message = 'Connecting to ${device.name}...';
      _isConnecting = true;
    });

    try {
      BluetoothConnection.toAddress(device.address).then((conn) {
        connection = conn;
        setState(() {
          message = "Connected to ${device.name}";
          messageColor = Colors.green;
          _isConnecting = false;
        });
      }).catchError((e) {
        setState(() {
          message = "Error during connection: $e";
          messageColor = Colors.red;
          _isConnecting = false;
        });
      });
    } catch (e) {
      setState(() {
        message = "Error during connection: $e";
        messageColor = Colors.red;
        _isConnecting = false;
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
                GestureDetector(
                  onTap: _isConnecting
                      ? null
                      : _showAvailableDevices, // disable onTap when connecting
                  child: _isConnecting
                      ? AnimatedOpacity(
                          opacity: _animation.value,
                          duration: const Duration(milliseconds: 200),
                          child: const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Icon(
                          Icons.bluetooth,
                          size: 100,
                          color: messageColor,
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(color: messageColor, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                if (!_isConnecting && _availableDevices.isNotEmpty)
                  SizedBox(
                    height: 200,
                    width: 300,
                    child: ListView.builder(
                      itemCount: _availableDevices.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            _availableDevices[index].name ?? 'Unknown Device',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onTap: () =>
                              _connectToDevice(_availableDevices[index]),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    if (connection != null && connection!.isConnected) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LockUnlockPage()),
                      );
                    } else {
                      setState(() {
                        message = "Failed to connect. Please try again.";
                        messageColor = Colors.red;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('Go to Lock/Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
