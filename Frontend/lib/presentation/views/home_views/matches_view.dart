import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';
import 'package:snooker_flutter/presentation/widgets/shared/qr_scanner.dart';
import 'package:snooker_flutter/services/http_services/matches_datasources.dart';

class MatchesView extends StatelessWidget {
  const MatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Partidos',
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            8.0, 30.0, 8.0, 8.0), // Ajusta los valores según tu preferencia
        child: ListView(
          children: <Widget>[
            _createCard(context, 'Crea un partido',
                'Crea un partido con como local', '/matches/new', '2'),
            const SizedBox(height: 8),
            _createCard(context, 'Encuentra partidos',
                'Busca partidos públicos', '/matches/list', '2'),
            const SizedBox(height: 8),
            _createCard(context, 'Mis partidos', 'Visualiza tus partidos',
                '/matches/my_matches', '2'),
            const SizedBox(height: 8),
            _createCard(context, 'Mis invitaciones',
                'Acepta o rechaza tus invitaciones', '/my_requests', '2'),
            const SizedBox(height: 8),
            _createScanQrCard(context),
          ],
        ),
      ),
    );
  }

  Widget _createCard(
      BuildContext context, String title, String subtitle, String url, String img) {
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
              Image.asset('lib/config/assets/images/$img.png',
                  width: 150), // Ajusta el ancho de la imagen
            ],
          ),
        ),
      ),
    );
  }

  Widget _createScanQrCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QrCodeScanner(
              setResult: (result) {
                if (result != null) {
                  Navigator.of(context).pop(); // Cierra el escáner QR
                  // Ejecuta el siguiente código después de un breve retraso para evitar conflictos de navegación.
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _showJoinMatchDialog(context, result);
                  });
                }
              },
            ),
          ),
        );
      },
      child: const Card(
        child: SizedBox(
          height: 150,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Escanea un QR', style: TextStyle(fontSize: 20)),
                      Text('Escanea un código QR para unirte a un partido',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              Icon(Icons.qr_code_scanner, size: 100), // Ícono de escaneo QR
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinMatchDialog(BuildContext context, String matchId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _JoinMatchDialog(matchId: matchId);
      },
    );
  }
}

class _JoinMatchDialog extends StatefulWidget {
  const _JoinMatchDialog({required this.matchId});

  final String matchId;

  @override
  State<_JoinMatchDialog> createState() => _JoinMatchDialogState();
}

class _JoinMatchDialogState extends State<_JoinMatchDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unirse al partido'),
      content: const Text('¿Quieres unirte a este partido?'),
      actions: <Widget>[
        TextButton(
          child: const Text('No'),
          onPressed: () {
            Navigator.of(context).pop(); // Cierra el diálogo
          },
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true; // Activa el indicador de carga
                  });

                  // Llamar a la función joinWithQr y mostrar el resultado
                  String responseMessage = await MatchService.getInstance()
                      .joinWithQr(widget.matchId);

                  // Determinar el color del SnackBar según el resultado
                  Color snackBarColor =
                      responseMessage == 'Te has unido correctamente'
                          ? Colors.green
                          : Colors.red;

                  // Mostrar el resultado en un SnackBar
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(responseMessage),
                        backgroundColor: snackBarColor,
                      ),
                    );
                  }

                  if (responseMessage == 'Te has unido correctamente' &&
                      context.mounted) {
                    context.push('/matches/${widget.matchId}');
                  }

                  setState(() {
                    _isLoading = false; // Desactiva el indicador de carga
                  });

                  if (context.mounted) {
                    Navigator.of(context).pop(); // Cierra el diálogo
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                  ),
                )
              : const Text('Sí'),
        ),
      ],
    );
  }
}
