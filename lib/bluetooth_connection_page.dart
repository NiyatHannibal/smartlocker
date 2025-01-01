import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'lock_unlock_page.dart';

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({Key? key}) : super(key: key);

  @override
  _BluetoothConnectionPageState createState() =>
      _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage>
    with SingleTickerProviderStateMixin {
  BluetoothConnection? _connection;
  String _message = 'Tap the Bluetooth icon to start';
  Color _messageColor = Colors.white;
  bool _isConnecting = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<BluetoothDevice> _availableDevices = [];
  bool _isBluetoothEnabled = false;

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
    if (_connection != null && _connection!.isConnected) {
      _connection!.dispose();
    }
    super.dispose();
  }

  Future<void> _checkBluetoothEnabled() async {
    try {
      _isBluetoothEnabled =
          await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (!_isBluetoothEnabled) {
        await FlutterBluetoothSerial.instance.requestEnable();
        _isBluetoothEnabled = true;
      }
    } catch (e) {
      setState(() {
        _message = "Error during Bluetooth check: $e";
        _messageColor = Colors.red;
      });
      _isBluetoothEnabled = false;
    }
    if (_isBluetoothEnabled == true) {
      setState(() {
        _message = "Bluetooth Disabled. Tap the Icon to Enable";
      });
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _message = 'Scanning for devices...';
      _isConnecting = true;
      _availableDevices = [];
    });

    try {
      FlutterBluetoothSerial.instance
          .startDiscovery()
          .listen((result) {
            if (!_availableDevices
                .any((element) => element.address == result.device.address)) {
              _availableDevices.add(result.device);
              setState(() {
                _message = 'Found ${result.device.name}';
              });
            }
          })
          .asFuture()
          .then((_) {
            _connectToTargetDevice();
          })
          .catchError((e) {
            setState(() {
              _message = "Error during Bluetooth discovery: $e";
              _messageColor = Colors.red;
              _isConnecting = false;
            });
          });
    } catch (e) {
      setState(() {
        _message = "Error during Bluetooth discovery: $e";
        _messageColor = Colors.red;
        _isConnecting = false;
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _connectToTargetDevice() async {
    final hc05Device = _availableDevices
        .firstWhereOrNull((device) => device.name?.contains("HC-05") == true);

    if (hc05Device != null) {
      _connectToDevice(hc05Device);
    } else {
      setState(() {
        _message = "HC-05 Device not found";
        _messageColor = Colors.red;
      });
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _message = 'Connecting to ${device.name}...';
      _isConnecting = true;
    });

    try {
      BluetoothConnection.toAddress(device.address).then((conn) {
        _connection = conn;
        if (_connection != null && device.name != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LockUnlockPage(
                      connection: _connection!,
                      deviceName: device.name!,
                    )),
          );
        }
        setState(() {
          _message = "Connected to ${device.name}";
          _messageColor = Colors.green;
          _isConnecting = false;
        });
      }).catchError((e) {
        setState(() {
          _message = "Error during connection: $e";
          _messageColor = Colors.red;
          _isConnecting = false;
        });
      });
    } catch (e) {
      setState(() {
        _message = "Error during connection: $e";
        _messageColor = Colors.red;
        _isConnecting = false;
      });
    }
  }

  void _showAvailableDevices() async {
    if (_isBluetoothEnabled) {
      _startDiscovery();
    } else {
      _checkBluetoothEnabled();
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
                  onTap: _isConnecting ? null : _showAvailableDevices,
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
                          color:
                              _isBluetoothEnabled ? _messageColor : Colors.grey,
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  _message,
                  style: TextStyle(color: _messageColor, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
