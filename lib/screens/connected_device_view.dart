import 'dart:async';
import 'dart:convert';

import 'package:esp_people_counter_mobile/utils/bt_uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConnectedDeviceView extends StatefulWidget {
  ConnectedDeviceView({super.key, required this.device});

  final BluetoothDevice device;
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};
  final _writeController = TextEditingController();

  @override
  ConnectedDeviceViewState createState() => ConnectedDeviceViewState();
}

class ConnectedDeviceViewState extends State<ConnectedDeviceView> {
  late final BluetoothCharacteristic? writeHandler;
  late final BluetoothCharacteristic? readHandler;
  late final StreamSubscription<List<int>>? notificationsStream;
  List<BluetoothService> services = [];
  String _peopleCounter = "";

  @override
  void initState() {
    super.initState();
    getServices();
  }

  @override
  void dispose() {
    notificationsStream?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  void initWriteHandler(BluetoothCharacteristic characteristic) {
    writeHandler = characteristic;
  }

  void readCharacteristic(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    var value = await characteristic.read();
    setState(() {
      widget.readValues[characteristic.uuid] = value;
    });
  }

  void notificationsSubscribe(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    notificationsStream = characteristic.lastValueStream.listen((value) {
      var responseMessage = String.fromCharCodes(value);
      if (characteristic.characteristicUuid == peopleCounterBtUuid) {
        setState(() {
          _peopleCounter = responseMessage;
        });
      }
      setState(() {
        widget.readValues[characteristic.uuid] = value;
      });
    });
  }

  void getServices() async {
    services = await widget.device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.read) {
          readCharacteristic(characteristic);
        }
        if (characteristic.properties.write) {
          initWriteHandler(characteristic);
        }
        if (characteristic.properties.notify) {
          notificationsSubscribe(characteristic);
        }
      }
    }
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              child:
                  const Text('Обновить', style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                widget.readValues[characteristic.uuid] =
                    await characteristic.read();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('Отправить',
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Отправить"),
                        content: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: widget._writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Отправить"),
                            onPressed: () {
                              characteristic.write(utf8
                                  .encode(widget._writeController.value.text));
                              Navigator.pop(context);
                            },
                          ),
                          TextButton(
                            child: const Text("Закрыть"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('Получение данных',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {},
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  List<Widget> _buildServiceCharacteristics(List<BluetoothService> services) {
    return services
        .map((service) => ExpansionTile(
            title: Text(service.uuid.toString()),
            children: service.characteristics
                .where((characteristic) =>
                    characteristic.properties.write ||
                    characteristic.properties.read ||
                    characteristic.properties.notify)
                .map(
                  (characteristic) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(characteristic.uuid.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: _buildReadWriteNotifyButton(characteristic),
                      ),
                      Row(
                        children: [
                          Text(String.fromCharCodes(
                              widget.readValues[characteristic.uuid] ?? [])),
                          Text(
                              '${widget.readValues[characteristic.uuid] ?? []}')
                        ],
                      ),
                      const Divider(),
                    ],
                  ),
                )
                .toList()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.device.platformName)),
        body: ListView(
          padding: const EdgeInsets.all(8),
          children: <Widget>[
            Text(_peopleCounter),
            ExpansionTile(
                title: const Text('Другие характеристики'),
                children: _buildServiceCharacteristics(services))
          ],
        ));
  }
}
