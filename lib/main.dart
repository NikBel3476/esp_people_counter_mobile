import 'dart:async';

import 'package:esp_people_counter_mobile/screens/bluetooth_off_screen.dart';
import 'package:esp_people_counter_mobile/screens/bluetooth_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const EspPeopleCounterApp());
}

class EspPeopleCounterApp extends StatelessWidget {
  const EspPeopleCounterApp({super.key});

  static const title = 'People counter';

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: title,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MainPage(title: title),
      );
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    super.initState();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _adapterState == BluetoothAdapterState.on
          ? BluetoothScanScreen(title: widget.title)
          : BluetoothOffScreen(adapterState: _adapterState);
}
