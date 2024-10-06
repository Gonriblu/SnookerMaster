import 'package:flutter/material.dart';
import 'package:snooker_flutter/entities/project_statistics.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_statistic_card.dart';
import 'package:snooker_flutter/services/http_services/statistics_datasource.dart';

class ProjectStatisticsScreen extends StatefulWidget {
  static const name = 'project-statistics-screen';
  const ProjectStatisticsScreen({super.key, required this.id});
  final String id;

  @override
  State<ProjectStatisticsScreen> createState() =>
      _ProjectStatisticsScreenScreenState();
}

class _ProjectStatisticsScreenScreenState extends State<ProjectStatisticsScreen> {
  bool _isDataLoaded = false;
  ProjectStatistics? projectStatistics;

  _loadData() async {
    projectStatistics =
        await StatisticsService.getInstance().getProjectStatistics(widget.id);
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
        appBar: CustomAppBar(title: 'Estadísticas'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (projectStatistics == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Estadísticas'),
        body: Center(
          child: Text('Error al cargar las estadísticas del proyecto.'),
        ),
      );
    }

    final stats = projectStatistics!;
    return Scaffold(
      appBar: const CustomAppBar(title: 'Estadísticas'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CustomStatisticCard(
            label: 'Total de Tiros',
            value: stats.totalPlays?.toString() ?? 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Tasa de Éxito',
            value: stats.successRate != null ? '${stats.successRate}%' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Promedio de Ángulo',
            value: stats.angleMean != null ? '${stats.angleMean}°' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Ángulo Mínimo',
            value: stats.angleMin != null ? '${stats.angleMin}°' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Ángulo Máximo',
            value: stats.angleMax != null ? '${stats.angleMax}°' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Desviación Estándar del Ángulo',
            value: stats.angleStdev != null ? '${stats.angleStdev}' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Promedio de Distancia',
            value: stats.distanceMean != null ? '${stats.distanceMean}' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Distancia Mínima',
            value: stats.distanceMin != null ? '${stats.distanceMin}' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Distancia Máxima',
            value: stats.distanceMax != null ? '${stats.distanceMax}' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Desviación Estándar de Distancia',
            value: stats.distanceStdev != null ? '${stats.distanceStdev}' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Conteo de Éxitos',
            value: stats.successCount != null ? '${stats.successCount}' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Conteo de Fallos',
            value: stats.failCount != null ? '${stats.failCount}' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Promedio de Ángulo en Éxitos',
            value: stats.angleMeanSuccess != null ? '${stats.angleMeanSuccess}°' : 'Sin datos',
          ),
          CustomStatisticCard(
            label: 'Promedio de Distancia en Éxitos',
            value: stats.distanceMeanSuccess != null ? '${stats.distanceMeanSuccess}' : 'Sin datos',
          ),
        ],
      ),
    );
  }
}
