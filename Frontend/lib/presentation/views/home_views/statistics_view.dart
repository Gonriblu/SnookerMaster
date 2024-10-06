import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulando datos de estadísticas
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Estadísticas',
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            8.0, 60.0, 8.0, 8.0), // Ajusta los valores según tu preferencia
        child: ListView(
          children: <Widget>[
            _createCard(context, 'Estadísticas generales',
                'Da un repaso a todo tu histórico', '/my_general_statistics'),
            const SizedBox(height: 8),
            _createCard(
                context,
                'Analizar proyecto',
                'Accede a las estadisticas de uno de tus proyectos',
                '/my_projects/statistics'),
            const SizedBox(height: 8),
            _createCard(
                context,
                'Analizar jugada',
                'Echa un vistazo a las estadísticas de una jugada concreta',
                '/my_plays'),
          ],
        ),
      ),
    );
  }

  Widget _createCard(
      BuildContext context, String title, String subtitle, String url) {
    return GestureDetector(
      onTap: () {
        context.push(url);
      },
      child: Card(
        child: SizedBox(
          height: 150,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(
                      16.0), // Añade un relleno a todos los lados del texto
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: const TextStyle(fontSize: 20)),
                      Text(subtitle, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              Image.asset('lib/config/assets/images/3.png',
                  width: 150), // Ajusta el ancho de la imagen
            ],
          ),
        ),
      ),
    );
  }
}
