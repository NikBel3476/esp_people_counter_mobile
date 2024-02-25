import 'package:flutter/material.dart';

import '../widgets/available_device_list.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  BluetoothScanScreenState createState() => BluetoothScanScreenState();
}

class BluetoothScanScreenState extends State<BluetoothScanScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Padding(
            padding: EdgeInsets.only(top: 8), child: AvailableDeviceList()),
      );
}
