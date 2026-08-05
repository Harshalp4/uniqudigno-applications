import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Line trend (health-score history, report parameter trends). Teal line with a
/// soft gradient fill.
class TrendChart extends StatelessWidget {
  final List<double> values;
  final double height;
  const TrendChart({super.key, required this.values, this.height = 140});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Not enough data to show a trend yet')),
      );
    }

    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final minY = (values.reduce((a, b) => a < b ? a : b) - 5).clamp(0, 100).toDouble();
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 5).clamp(0, 100).toDouble();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.teal700,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.teal700.withValues(alpha: 0.25),
                    AppColors.teal700.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
