import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EloChart extends StatelessWidget {
  final List<Map<String, dynamic>>? lastMatchesInfo;
  final bool showSpots; // Nuevo parámetro para controlar la visibilidad de los puntos

  const EloChart({super.key, this.lastMatchesInfo, this.showSpots = false});

  @override
  Widget build(BuildContext context) {
    if (lastMatchesInfo == null || lastMatchesInfo!.isEmpty) {
      return const Center(
        child: Text(
          'No hay suficiente información todavía',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    // Convertir los datos a puntos para el gráfico
    final spots = _getEloSpots(lastMatchesInfo!);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(_buildLineChartData(spots)),
    );
  }

  LineChartData _buildLineChartData(List<FlSpot> spots) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              return _buildBottomTitle(value, meta);
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return _buildLeftTitle(value, meta);
            },
            reservedSize: 42,
            interval: 1,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: spots.isEmpty ? 0 : spots.length - 1,
      minY: 1,
      maxY: 10,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.green],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: showSpots, // Mostrar u ocultar puntos según showSpots
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.green.withOpacity(0.3)
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: showSpots, // Habilitar interacción táctil solo si showSpots es true
        handleBuiltInTouches: false,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              const textStyle = TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              );
              return LineTooltipItem(
                touchedSpot.y.toStringAsFixed(2), // Mostrar solo el valor de y con 2 decimales
                textStyle,
              );
            }).toList();
          },
        ),
      ),
      showingTooltipIndicators: showSpots
          ? List.generate(spots.length, (index) => ShowingTooltipIndicators([
                LineBarSpot(
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                  ),
                  0,
                  spots[index],
                ),
              ]))
          : [],
    );
  }

  List<FlSpot> _getEloSpots(List<Map<String, dynamic>> matchesInfo) {
    List<FlSpot> spots = [];
    for (var i = 0; i < matchesInfo.length; i++) {
      final endElo = matchesInfo[i]['end_elo'] as double?;
      if (endElo != null) {
        spots.add(FlSpot(i.toDouble(), double.parse(endElo.toStringAsFixed(2)))); // Limitar a 2 decimales
      }
    }
    return spots;
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    final int index = value.toInt();
    if (index < 0 ||
        lastMatchesInfo == null ||
        index >= lastMatchesInfo!.length) {
      return const Text('');
    }

    final matchDate = DateTime.parse(lastMatchesInfo![index]['match_datetime']);
    final formattedDate = "${matchDate.day}/${matchDate.month}";

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(formattedDate, style: style),
    );
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    return Text('${value.toInt()}', style: style, textAlign: TextAlign.left);
  }
}
