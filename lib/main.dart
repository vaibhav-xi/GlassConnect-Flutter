import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FlutterBlue _flutterBlue;
  BluetoothDevice? _device;
  late BluetoothService _service;
  late BluetoothCharacteristic _characteristic;
  String _wifiName = '';
  String _wifiPassword = '';

  @override
  void initState() {
    super.initState();
    _flutterBlue = FlutterBlue.instance;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Glass Connect'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _scanForDevices,
                child: const Text('Scan for devices'),
              ),
              const SizedBox(height: 20),
              Text('Connected to: ${_device?.name ?? 'None'}'),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(labelText: 'WiFi Name'),
                onChanged: (value) => _wifiName = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'WiFi Password'),
                onChanged: (value) => _wifiPassword = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendWifiCredentials,
                child: const Text('Send WiFi credentials'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scanForDevices() async {
    _flutterBlue.startScan(timeout: const Duration(seconds: 4));
    _flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        print("DEVICE: ${result.device.name}");
        if (result.device.name == 'GlassConnect2') {
          _device = result.device;
          _connectToDevice();
          break;
        }
      }
    });
  }

  void _connectToDevice() async {
    await _device!.connect();
    List<BluetoothService> services = await _device!.discoverServices();
    _service = services.firstWhere((service) => service.uuid == Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b'));
    _characteristic = _service.characteristics.firstWhere((characteristic) => characteristic.uuid == Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8'));
  }

  void _sendWifiCredentials() async {
    if (_device == null) {
        print("No device selected.");
        return;
    }

    String wifiCredentials = '$_wifiName,$_wifiPassword';
    print("Sending WiFi credentials: $wifiCredentials");

    List<int> bytes = utf8.encode(wifiCredentials);
    print("Sending bytes: $bytes");

    try {
        await _characteristic.write(bytes);
        print("WiFi credentials sent successfully.");
    } catch (e) {
        print("Error sending WiFi credentials: $e");
    }
}

}