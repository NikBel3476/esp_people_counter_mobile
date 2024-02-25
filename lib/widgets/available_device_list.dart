import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../screens/connected_device_view.dart';
import '../utils/snackbar.dart';

class AvailableDeviceList extends StatefulWidget {
  const AvailableDeviceList({super.key});

  @override
  State<AvailableDeviceList> createState() => AvailableDeviceListState();
}

class AvailableDeviceListState extends State<AvailableDeviceList> {
  late Stream<List<ScanResult>> _scanResults;

  @override
  void initState() {
    super.initState();
    _scanResults = FlutterBluePlus.scanResults;
    startScan();
  }

  @override
  void dispose() {
    if (FlutterBluePlus.isScanningNow) FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future startScan() async {
    try {
      if (FlutterBluePlus.isScanningNow) FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start scan error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void onDeviceConnectButtonTap(BluetoothDevice device) async {
    try {
      if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
      await device.connect();

      if (!mounted) return;

      await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ConnectedDeviceView(device: device)));

      startScan();
    } on PlatformException catch (e) {
      if (e.code != 'already_connected') {
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ScanResult>>(
      stream: _scanResults,
      initialData: const [],
      builder: (c, snapshot) => ListView(
          children: snapshot.data!
              .map((result) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(result.device.platformName.isEmpty
                                  ? '(неизвестное устройство)'
                                  : result.device.platformName),
                              Text(result.device.remoteId.toString()),
                            ],
                          ),
                        ),
                        TextButton(
                            onPressed: result.advertisementData.connectable
                                ? () {
                                    onDeviceConnectButtonTap(result.device);
                                  }
                                : null,
                            child: const Text(
                              'Подключиться',
                              style: TextStyle(color: Colors.blue),
                            )),
                      ],
                    ),
                  ))
              .toList()));
}
