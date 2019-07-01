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
      read();
    }
  }

  Future<void> read() async {
    for (int i = 0; i < 9; i++) {
      await characteristics[i].read().catchError((err) {});
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
      for (int i = 0; i < 9; i++) {
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child:
          (widget.characteristics != null && widget.characteristics.isNotEmpty)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                      Text("Pitch: ${widget.characteristics[0].lastValue}"),
//            Text("${characteristics[1].lastValue[0].toSigned(8)}"),
                      Text("Yaw: ${widget.characteristics[1].lastValue}"),
                      Text("Roll: ${widget.characteristics[2].lastValue}"),
                      Container(
                        height: 200,
                        child: (widget.characteristics[4].lastValue.isNotEmpty)
                            ? StackedBarChart([
                                widget.characteristics[3].lastValue[0],
                                widget.characteristics[4].lastValue[0],
                                widget.characteristics[5].lastValue[0],
                                widget.characteristics[8].lastValue[0]
                              ], false)
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
      new ChartColumn('Signal quality', values[3])
    ];

    final maxData = [
      new ChartColumn('Alpha', 255),
      new ChartColumn('Beta', 255),
      new ChartColumn('Theta', 255),
      new ChartColumn('Signal quality', 255),
    ];

    return [
      new charts.Series<ChartColumn, String>(
        id: 'max',
        domainFn: (ChartColumn col, _) => col.key,
        measureFn: (ChartColumn col, _) => col.value,
        data: maxData,
      ),
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
      barGroupingType: charts.BarGroupingType.stacked,
      behaviors: [
        new charts.PercentInjector(
            totalType: charts.PercentInjectorTotalType.domain)
      ],
      primaryMeasureAxis: new charts.PercentAxisSpec(),
    );
  }
}

/// Sample ordinal data type.
class ChartColumn {
  final String key;
  final int value;

  ChartColumn(this.key, this.value);
}
