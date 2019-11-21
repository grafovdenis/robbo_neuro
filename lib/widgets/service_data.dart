import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as spp;
import 'package:robbo_neuro/widgets/stacked_bar_chart.dart';

class ServiceDataWidget extends StatefulWidget {
  final BluetoothDevice device;

  const ServiceDataWidget({Key key, this.device}) : super(key: key);
  @override
  ServiceDataWidgetState createState() => ServiceDataWidgetState();
}

class ServiceDataWidgetState extends State<ServiceDataWidget> {
  int pitch = 0;
  int roll = 0;
  int left = 0;
  int right = 0;
  spp.BluetoothConnection connection;
  List<BluetoothService> services;
  List<BluetoothCharacteristic> characteristics;
  Timer _timer;
  bool _start = false;
  bool ready = false;
  bool connected = false;

  void prepare() async {
    try {
      if (connection == null || !connection.isConnected) {
        connection =
            await spp.BluetoothConnection.toAddress('00:06:66:7D:AB:31');
        print("CAR CONNECTED");
        ready = true;
        setState(() {});
        connection.input.listen((data) {
          ready = true;

          if (String.fromCharCodes(data).contains('!')) {
            connection.finish(); // Closing connection
            print('Disconnecting by local host');
          }
        }).onDone(() {
          print('Disconnected by remote request');
        });
      }
    } catch (e) {}
    services = await widget.device?.discoverServices();
    characteristics = services[2].characteristics;
  }

  void read() async {
    try {
      await characteristics[0].read();
      await characteristics[2].read();
      await characteristics[3].read();
      setState(() {});
    } catch (err) {}
  }

  Future<void> write() async {
    try {
      if (pitch >= 0) {
        if (roll >= 0) {
          num _turn = 1 - roll / 90;
          left = (pitch / 90 * 63 * _turn).toInt();
          right = (pitch / 90 * 63).toInt();
        } else {
          num _turn = 1 + roll / 90;
          left = (pitch / 90 * 63).toInt();
          right = (pitch / 90 * 63 * _turn).toInt();
        }
      } else {
        left = (-pitch / 90 * 63 + 63).toInt();
        right = (-pitch / 90 * 63 + 63).toInt();
      }
      if (pitch <= 90 && pitch >= -90 && left >= 0 && right >= 0) {
        // connection.output.add(Uint8List.fromList([
        //   99,
        //   right,
        //   left,
        //   36,
        // ]));

        connection.output.add(Uint8List.fromList([
          103,
          right,
          left,
          0,
          24,
          36,
        ]));
        await connection.output.allSent;
        ready = false;
      }
    } catch (e) {
      print(e);
    }
  }

  void stop() async {
    _timer?.cancel();
  }

  void start() async {
    // _sppTimer = Timer.periodic(Duration(microseconds: 100), (Timer t) {
    //   write();
    // });
    const refresh_rate = const Duration(milliseconds: 100);
    _timer = Timer.periodic(refresh_rate, (Timer t) {
      read();
      write();
    });
  }

  @override
  void initState() {
    prepare();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (connected) connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    connected = connection != null && connection.isConnected;
    if ((characteristics != null &&
        characteristics.isNotEmpty &&
        characteristics[2].lastValue.isNotEmpty)) {
      pitch = int.tryParse(
              "${characteristics[0].lastValue[1].toUnsigned(8).toRadixString(16)}${characteristics[0].lastValue[0].toUnsigned(8).toRadixString(16)}",
              radix: 16)
          .toSigned(15);
      roll = int.tryParse(
              "${characteristics[2].lastValue[1].toUnsigned(8).toRadixString(16)}${characteristics[2].lastValue[0].toUnsigned(8).toRadixString(16)}",
              radix: 16)
          .toSigned(15);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: (characteristics != null &&
                  characteristics.isNotEmpty &&
                  characteristics[3].lastValue.isNotEmpty)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                      Text("Pitch: $pitch"),
                      Text("Roll : $roll"),
                      Container(height: 10),
                      Text("Alpha : ${characteristics[3].lastValue[0]} %"),
                      Container(
                        height: 200,
                        child: (characteristics[3].lastValue.isNotEmpty)
                            ? StackedBarChart([
                                characteristics[3].lastValue[0],
                                127,
                                127,
                                127,
                                127,
                              ], true)
                            : Container(),
                      ),
                      Text("Left : $left"),
                      Text("Right: $right")
                    ])
              : Container(
                  height: 200,
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Car is ${(connected) ? "connected" : "not connected"}"),
        ),
        (connected)
            ? FlatButton(
                color: Colors.blue,
                child: Text((!_start) ? "Start!" : "Stop!"),
                onPressed: () {
                  setState(() {
                    _start = !_start;
                    (_start) ? start() : stop();
                  });
                },
              )
            : Container(),
      ],
    );
  }
}
