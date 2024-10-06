import 'package:flutter/material.dart';
import 'package:snooker_flutter/entities/general_statistic.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_statistic_card.dart';
import 'package:snooker_flutter/services/http_services/statistics_datasource.dart';

class GeneralStatisticsScreen extends StatefulWidget {
  static const name = 'general-statistics-screen';
  const GeneralStatisticsScreen({super.key});

  @override
  State<GeneralStatisticsScreen> createState() =>
      _GeneralStatisticsScreenState();
}

class _GeneralStatisticsScreenState extends State<GeneralStatisticsScreen> {
  bool _isDataLoaded = false;
  GeneralStatistics? generalStatistics;

  _loadData() async {
    generalStatistics =
        await StatisticsService.getInstance().getMyGeneralStatistics();
    setState(() {
      _isDataLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Estadísticas generales'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (generalStatistics == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Estadísticas generales'),
        body: Center(
          child: Text('Error al cargar el proyecto.'),
        ),
      );
    }
    final stats = generalStatistics!;
    return Scaffold(
      appBar: const CustomAppBar(title: 'Estadísticas generales'),
      body: ListView(padding: const EdgeInsets.all(16.0), children: [
        CustomStatisticCard(
            label: 'Jugadas Totales', value: stats.totalPlays.toString()),
        CustomStatisticCard(
            label: 'Tasa de Éxito', value: '${stats.successRate}%'),
        CustomStatisticCard(
            label: 'Promedio de Ángulo', value: '${stats.angleMean}°'),
        CustomStatisticCard(
            label: 'Ángulo Mínimo', value: '${stats.angleMin}°'),
        CustomStatisticCard(
            label: 'Ángulo Máximo', value: '${stats.angleMax}°'),
        CustomStatisticCard(
            label: 'Desviación Estándar del Ángulo',
            value: '${stats.angleStdev}'),
        CustomStatisticCard(
            label: 'Promedio de Distancia', value: '${stats.distanceMean}'),
        CustomStatisticCard(
            label: 'Distancia Mínima', value: '${stats.distanceMin}'),
        CustomStatisticCard(
            label: 'Distancia Máxima', value: '${stats.distanceMax}'),
        CustomStatisticCard(
            label: 'Desviación Estándar de la Distancia',
            value: '${stats.distanceStdev}'),
        CustomStatisticCard(
            label: 'Cantidad de Éxitos', value: '${stats.successCount}'),
        CustomStatisticCard(
            label: 'Cantidad de Fallos', value: '${stats.failCount}'),
        CustomStatisticCard(
            label: 'Promedio de Ángulo en Éxitos',
            value: '${stats.angleMeanSuccess}°'),
        CustomStatisticCard(
            label: 'Promedio de Distancia en Éxitos',
            value: '${stats.distanceMeanSuccess}'),
      ]),
    );
  }
}
