import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '/models/statistic.dart';

class StockMovementChart extends StatelessWidget {
  final List<StockMovementData> data;
  final int totalIn;
  final int totalOut;

  const StockMovementChart({
    super.key,
    required this.data,
    required this.totalIn,
    required this.totalOut,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: const Text(
          'No data available',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    // Find max value for scaling
    int maxValue = 0;
    for (var item in data) {
      if (item.stockIn > maxValue) maxValue = item.stockIn;
      if (item.stockOut > maxValue) maxValue = item.stockOut;
    }
    maxValue = (maxValue * 1.2).ceil(); // Add 20% padding
    
    // Ensure maxValue is at least 4 to avoid division issues
    if (maxValue < 4) maxValue = 4;
    
    final double interval = maxValue / 4.0;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= data.length) return const SizedBox();
                      final date = data[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: maxValue.toDouble(),
              lineBarsData: [
                // Stock In line (black)
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.stockIn.toDouble(),
                    );
                  }).toList(),
                  isCurved: true,
                  color: Colors.black87,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.black87,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.black87.withValues(alpha: 0.1),
                  ),
                ),
                // Stock Out line (grey)
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.stockOut.toDouble(),
                    );
                  }).toList(),
                  isCurved: true,
                  color: Colors.grey,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.grey,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.black87,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = data[spot.x.toInt()].date;
                      final isIn = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isIn ? 'In' : 'Out'}: ${spot.y.toInt()}\n${DateFormat('MMM dd').format(date)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              Icons.circle,
              'In',
              totalIn.toString(),
              Colors.black87,
            ),
            const SizedBox(width: 32),
            _buildLegendItem(
              Icons.circle,
              'Out',
              totalOut.toString(),
              Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}