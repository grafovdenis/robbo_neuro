import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:robbo_neuro/data/chart_column.dart';

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