import 'package:flutter/material.dart';
import 'package:snooker_flutter/entities/play_statistics.dart';
import 'package:snooker_flutter/entities/project.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_play_carousel.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_project_carousel.dart';
import 'package:snooker_flutter/services/http_services/plays_datasource.dart';
import 'package:snooker_flutter/services/http_services/projects_datasource.dart';

class ProcessView extends StatefulWidget {
  final bool
      shouldReloadData; 

  const ProcessView({super.key, this.shouldReloadData = false});

  @override
  State<ProcessView> createState() => _ProcessViewState();
}

class _ProcessViewState extends State<ProcessView> {
  bool _isDataLoaded = false;
  List<Project>? myProjects;
  List<Play>? myPlays;
  String? errorMessage;

  Future<void> _loadData() async {
    try {
      myProjects = await ProjectService.getInstance().getMyProjects(5);
      myPlays = await PlaysService.getInstance().getMyPlays(5);
      setState(() {
        _isDataLoaded = true;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        _isDataLoaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Verificar si se deben recargar los datos
    if (widget.shouldReloadData || !_isDataLoaded) {
      _loadData();
    }
  }

  void _showInfoModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limitaciones'),
          content: const Text(
            'Este módulo está diseñado para jugadores profesionales que buscan perfeccionar su técnica.\n'
            'El procesamiento de jugadas ofrece información aproximada, no exacta. Para obtener los mejores resultados, es crucial contar con un video de alta calidad y resolución.\n\n'
            'Los siguientes factores pueden afectar negativamente la calidad del procesamiento o incluso interrumpirlo:\n\n'
            '- Baja resolución del video\n'
            '- Pocos frames, lo que impide identificar correctamente la jugada\n'
            '- Exceso de frames, el video no debe superar los 450 frames\n'
            '- Obstrucciones en la jugada, como el cuerpo del jugador\n'
            '- Grabar la jugada con el semicírculo de la mesa en la parte más cercana\n'
            '- Alta velocidad de golpeo\n'
            '- Selección incorrecta de la tronera en la que se emboca la bola',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el modal
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        automaticallyImplyLeading: true,
        elevation: 4.0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16.0),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed:
                _showInfoModal,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), 
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomProjectCarousel(
                    title: 'Proyectos recientes',
                    height: 200,
                    itemsList: myProjects ?? [],
                    onProjectCreated: () {
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomPlayCarousel(
                    title: 'Jugadas recientes',
                    height: 350,
                    itemsList: myPlays ?? [],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
