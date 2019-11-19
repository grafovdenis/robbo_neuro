import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:robbo_neuro/widgets/stacked_bar_chart.dart';

class ServiceDataWidget extends StatefulWidget {
  final BluetoothDevice device;

  const ServiceDataWidget({Key key, this.device}) : super(key: key);
  @override
  ServiceDataWidgetState createState() => ServiceDataWidgetState();
}

class ServiceDataWidgetState extends State<ServiceDataWidget> {
  List<BluetoothService> services;
  List<BluetoothCharacteristic> characteristics;
  Timer _timer;

  Future<void> prepare() async {
    services = await widget.device?.discoverServices();
    characteristics = services[2].characteristics;
  }

  Future<void> read() async {
    try {
      for (int i = 0; i < 10; i++) {
        await characteristics[i].read();
      }
      setState(() {});
    } catch (err) {}
  }

  @override
  void initState() {
    prepare();
    const refresh_rate = const Duration(milliseconds: 100);
    _timer = Timer.periodic(refresh_rate, (Timer t) {
      read();
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int pitch;
    int yaw;
    int roll;
    if ((characteristics != null &&
        characteristics.isNotEmpty &&
        characteristics[2].lastValue.isNotEmpty)) {
      pitch = int.tryParse(
              "${characteristics[0].lastValue[1].toUnsigned(8).toRadixString(16)}${characteristics[0].lastValue[0].toUnsigned(8).toRadixString(16)}",
              radix: 16)
          .toSigned(15);
      yaw = int.tryParse(
              "${characteristics[1].lastValue[1].toUnsigned(8).toRadixString(16)}${characteristics[1].lastValue[0].toUnsigned(8).toRadixString(16)}",
              radix: 16)
          .toSigned(15);
      roll = int.tryParse(
              "${characteristics[2].lastValue[1].toUnsigned(8).toRadixString(16)}${characteristics[2].lastValue[0].toUnsigned(8).toRadixString(16)}",
              radix: 16)
          .toSigned(15);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: (characteristics != null &&
              characteristics.isNotEmpty &&
              characteristics[9].lastValue.isNotEmpty)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                  Text("Pitch: $pitch"),
                  Text("Yaw  : $yaw"),
                  Text("Roll : $roll"),
                  Container(height: 10),
                  Text("Alpha : ${characteristics[3].lastValue[0]} %"),
                  Text("Beta  : ${characteristics[4].lastValue[0]} %"),
                  Text("Theta : ${characteristics[5].lastValue[0]} %"),
                  Container(height: 10),
                  Text("Signal quailty: ${characteristics[8].lastValue[0]} %"),
                  Text("Charge        : ${characteristics[9].lastValue[0]} %"),
                  Container(
                    height: 200,
                    child: (characteristics[4].lastValue.isNotEmpty)
                        ? StackedBarChart([
                            characteristics[3].lastValue[0],
                            characteristics[4].lastValue[0],
                            characteristics[5].lastValue[0],
                            characteristics[8].lastValue[0],
                            characteristics[9].lastValue[0]
                          ], true)
                        : Container(),
                  )
                ])
          : Center(child: CircularProgressIndicator()),
    );
  }
}
