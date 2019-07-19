import 'dart:async';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_blue/flutter_blue.dart';

class ServiceData extends StatefulWidget {
  List<BluetoothCharacteristic> characteristics;

  ServiceData(List<BluetoothCharacteristic> characteristics) {
    if (characteristics.isNotEmpty)
      this.characteristics = characteristics;
    else {
      this.characteristics = List<BluetoothCharacteristic>(10);
    }
  }

  @override
  ServiceDataState createState() {
    return ServiceDataState();
  }
}

class ServiceDataState extends State<ServiceData> {
  Timer _timer;

  Future<void> read() async {
    try {
      for (int i = 0; i < 10; i++) {
        await widget.characteristics[i].read();
      }
      setState(() {});
    } catch (err) {}
  }

  @override
  void initState() {
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
    var pitch;
    var yaw;
    var roll;
    if ((widget.characteristics != null &&
        widget.characteristics.isNotEmpty &&
        widget.characteristics[0] != null)) {
      pitch = int.tryParse(
              "${widget.characteristics[0].lastValue[1].toUnsigned(8).toRadixString(16)}${widget.characteristics[0].lastValue[0].toUnsigned(8).toRadixString(16)}",
              radix: 16)
          .toSigned(15);
      yaw = int.tryParse(
              "${widget.characteristics[1].lastValue[1].toUnsigned(8).toRadixString(16)}${widget.characteristics[1].lastValue[0].toUnsigned(8).toRadixString(16)}",
              radix: 16)
          .toSigned(15);
      roll = int.tryParse(
              "${widget.characteristics[2].lastValue[1].toUnsigned(8).toRadixString(16)}${widget.characteristics[2].lastValue[0].toUnsigned(8).toRadixString(16)}",
              radix: 16)
          .toSigned(15);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: (widget.characteristics != null &&
              widget.characteristics.isNotEmpty &&
              widget.characteristics[0] != null)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                  Text("Pitch: $pitch"),
                  Text("Yaw  : $yaw"),
                  Text("Roll : $roll"),
                  Container(height: 10),
                  Text("Alpha : ${widget.characteristics[3].lastValue[0]} %"),
                  Text("Beta  : ${widget.characteristics[4].lastValue[0]} %"),
                  Text("Theta : ${widget.characteristics[5].lastValue[0]} %"),
                  Container(height: 10),
                  Text("Signal quailty: ${widget.characteristics[8].lastValue[0]} %"),
                  Text("Charge        : ${widget.characteristics[9].lastValue[0]} %"),
                  Container(
                    height: 200,
                    child: (widget.characteristics[4].lastValue.isNotEmpty)
                        ? StackedBarChart([
                            widget.characteristics[3].lastValue[0],
                            widget.characteristics[4].lastValue[0],
                            widget.characteristics[5].lastValue[0],
                            widget.characteristics[8].lastValue[0],
                            widget.characteristics[9].lastValue[0]
                          ], true)
                        : Container(),
                  )
                ])
          : Center(child: Text("No data")),
    );
  }
}

class StackedBarChart extends StatelessWidget {
  List<charts.Series> seriesList;
  final bool animate;
  final List<int> values;

  StackedBarChart(this.values, this.animate) {
    this.seriesList = _createChartData(values);
  }

  List<charts.Series<ChartColumn, String>> _createChartData(List<int> values) {
    final actualData = [
      new ChartColumn('Alpha', values[0]),
      new ChartColumn('Beta', values[1]),
      new ChartColumn('Theta', values[2]),
      new ChartColumn('Signal quality', values[3]),
      new ChartColumn('Charge', values[4])
    ];

    return [
      new charts.Series<ChartColumn, String>(
        id: 'data',
        domainFn: (ChartColumn col, _) => col.key,
        measureFn: (ChartColumn col, _) => col.value,
        data: actualData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return new charts.BarChart(
      // Configure the axis spec to show percentage values.
      seriesList,
      animate: animate,
    );
  }
}

/// Sample ordinal data type.
class ChartColumn {
  final String key;
  final int value;

  ChartColumn(this.key, this.value);
}
