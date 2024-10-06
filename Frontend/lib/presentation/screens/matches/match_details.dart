import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:snooker_flutter/entities/match.dart';
import 'package:snooker_flutter/entities/user.dart';
import 'package:snooker_flutter/presentation/widgets/shared/elo_chart.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'package:snooker_flutter/services/http_services/matches_datasources.dart';
import 'package:snooker_flutter/services/http_services/requests_datasource.dart';
import 'package:snooker_flutter/services/http_services/users_service.dart';

class MatchDetailsScreen extends StatefulWidget {
  static const name = 'match-details-screen';
  const MatchDetailsScreen({super.key, required this.id});
  final String id;

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  bool _isDataLoaded = false;
  Match? match;
  List<Color> gradientColors = [Colors.cyan, Colors.blue];
  String? userEmail;
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime? _parseMatchDatetime(String? dateTimeString) {
    if (dateTimeString == null) return null;

    try {
      final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      return dateFormat.parse(dateTimeString);
    } catch (e) {
      debugPrint("Date parse error: $e");
      return null;
    }
  }

  Future<void> _loadData() async {
    try {
      userEmail = await LoginService.getInstance().getEmail();
      match = await MatchService.getInstance().getMatch(widget.id);
      setState(() {
        _isDataLoaded = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar la partida'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    if (match == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error al cargar la partida.'),
        ),
      );
    }
    final matchDate = _parseMatchDatetime(match!.matchDatetime);
    final bool matchHasBegan =
        matchDate != null && matchDate.isBefore(DateTime.now());
    print(matchHasBegan);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Partido'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlayersSection(),
            const SizedBox(height: 16),
            _buildMatchDetailsSection(),
            const SizedBox(height: 16),
            if (match!.visitor != null && matchHasBegan) ...[
              _buildResultSection(), // Nueva sección para mostrar el resultado
              const SizedBox(height: 16),
            ],
            _buildStatisticsCard(
                'Últimos partidos de ${match!.local!.name}', match!.local),
            if (match!.visitor != null) const SizedBox(height: 16),
            if (match!.visitor != null)
              _buildStatisticsCard(
                  'Últimos partidos de ${match!.visitor!.name}',
                  match!.visitor),
          ],
        ),
      ),
    );
  }

  void _showInviteUserModal() {
    final TextEditingController emailController = TextEditingController();

    _selectedUser = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String? errorMessage;

            return AlertDialog(
              title: const Text('Enviar Invitación'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        errorMessage =
                            null; // Limpiar el mensaje de error antes de buscar
                      });

                      try {
                        dynamic result = await UsersService.getInstance()
                            .searchPlayer(emailController.text);
                        if (result is User) {
                          setState(() {
                            _selectedUser = result;
                          });
                        } else {
                          setState(() {
                            errorMessage = result as String?;
                            _selectedUser = null;
                          });
                        }
                      } catch (e) {
                        setState(() {
                          errorMessage =
                              'Error al buscar el usuario. Por favor, inténtelo de nuevo.';
                          _selectedUser = null;
                        });
                      }
                    },
                    child: const Text('Buscar'),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (_selectedUser != null) _buildUserCard(_selectedUser!),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedUser = null;
                    });
                  },
                  child: const Text('Cancelar'),
                ),
                if (_selectedUser != null)
                  ElevatedButton(
                    onPressed: () async {
                      String response = await RequestService.getInstance()
                          .invite(match!.id!, _selectedUser!.id!);

                      if (response == "Invitación enviada correctamente") {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }

                      Navigator.of(context).pop();
                      setState(() {
                        _selectedUser = null;
                      });
                    },
                    child: const Text('Enviar'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user.profilePhoto ?? ''),
              radius: 40.0,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elo: ${user.elo ?? ''}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinRequestModal() {
    final scaffoldContext =
        context; // Captura el contexto de la pantalla principal

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Solicitar unirme?'),
          content: const Text(
              '¿Estás seguro de que deseas solicitar unirte como jugador visitante?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                String response =
                    await RequestService.getInstance().requestJoin(match!.id!);

                if (response == "Invitación enviada correctamente") {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text(response),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text(response),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultSection() {
    final int localFrames = match!.localFrames ?? 0;
    final int visitorFrames = match!.visitorFrames ?? 0;
    final bool localResultAgreed = match!.localResultAgreed ?? false;
    final bool visitorResultAgreed = match!.visitorResultAgreed ?? false;

    final bool isLocal = userEmail == match!.local?.email;
    final bool isVisitor = userEmail == match!.visitor?.email;

    // Condiciones para mostrar botones o mensajes
    bool showConfirmRejectButtons =
        (isLocal && !localResultAgreed && visitorResultAgreed) ||
            (isVisitor && !visitorResultAgreed && localResultAgreed);
    bool showWaitingConfirmation =
        (isLocal && localResultAgreed && !visitorResultAgreed) ||
            (isVisitor && visitorResultAgreed && !localResultAgreed);
    bool showSetResultButton = !localResultAgreed && !visitorResultAgreed;

    if (!isLocal &&
        !isVisitor &&
        (!localResultAgreed || !visitorResultAgreed)) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Resultado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreText(localFrames, localFrames > visitorFrames),
                const Text(
                  '-',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                _buildScoreText(visitorFrames, visitorFrames > localFrames),
              ],
            ),
            const SizedBox(height: 16),
            if (showConfirmRejectButtons) ...[
              ElevatedButton(
                onPressed: () => _confirmResult(agreed: true),
                child: const Text('Confirmar Resultado'),
              ),
              ElevatedButton(
                onPressed: () => _confirmResult(agreed: false),
                child: const Text('Rechazar Resultado'),
              ),
            ],
            if (showWaitingConfirmation)
              const Text(
                'Esperando confirmación',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            if (showSetResultButton)
              ElevatedButton(
                onPressed: _showResultInputDialog,
                child: const Text('Poner resultado'),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmResult({required bool agreed}) async {
    String response;

    if (agreed) {
      // El usuario confirma el resultado sin cambios
      response = await MatchService.getInstance().confirmResult(
        true,
        match!.id!,
        null,
        null,
      );
      _loadData();
    } else {
      // El usuario rechaza el resultado y debe introducir uno nuevo
      final TextEditingController localController = TextEditingController();
      final TextEditingController visitorController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Proponer un nuevo resultado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: localController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Frames Local'),
                ),
                TextField(
                  controller: visitorController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Frames Visitante'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  int? localFrames = int.tryParse(localController.text);
                  int? visitorFrames = int.tryParse(visitorController.text);

                  if (localFrames != null && visitorFrames != null) {
                    // Envía el nuevo resultado al servidor
                    response = await MatchService.getInstance().confirmResult(
                      false,
                      match!.id!,
                      localFrames,
                      visitorFrames,
                    );

                    if (response == "Enviado correctamente") {
                      // Recargar los datos
                      await _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, ingresa valores válidos.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildScoreText(int score, bool isHighlighted) {
    return Text(
      '$score',
      style: TextStyle(
        fontSize: isHighlighted ? 32 : 24,
        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        color: isHighlighted ? Colors.blue : Colors.black,
      ),
    );
  }

  void _showResultInputDialog() {
    final TextEditingController localController = TextEditingController();
    final TextEditingController visitorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escribe el resultado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: localController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Frames Local'),
              ),
              TextField(
                controller: visitorController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Frames Visitante'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                int? localFrames = int.tryParse(localController.text);
                int? visitorFrames = int.tryParse(visitorController.text);

                if (localFrames != null && visitorFrames != null) {
                  // Send the result to the server
                  String response = await MatchService.getInstance().sendResult(
                    localFrames,
                    visitorFrames,
                    match!.id!,
                  );

                  if (response == "Resultado enviado correctamente") {
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, ingresa valores válidos.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayersSection() {
    final bool isLocal = userEmail == match!.local?.email;

    return Row(
      children: [
        Expanded(
          child: _buildPlayerCard(
            title: 'Jugador Local',
            user: match!.local,
            elo: match!.local?.elo,
            alignment: CrossAxisAlignment.start,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPlayerCard(
            title: 'Jugador Visitante',
            user: match!.visitor,
            elo: match!.visitor?.elo,
            alignment: CrossAxisAlignment.end,
            onTap: !isLocal && match!.visitor == null
                ? _showJoinRequestModal
                : null,
            isLocal: isLocal,
            showQrOption: isLocal && match!.visitor == null,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard({
    required String title,
    required User? user,
    required double? elo,
    required CrossAxisAlignment alignment,
    VoidCallback? onTap,
    bool showQrOption = false,
    bool isLocal = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: alignment,
            children: [
              if (user != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(user.profilePhoto ?? ''),
                  radius: 40.0,
                )
              else if (!isLocal)
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: 40.0,
                  child: const Icon(Icons.add, size: 40),
                ),
              const SizedBox(height: 8),
              if (user == null && !isLocal)
                const Column(
                  children: [
                    SizedBox(
                        height: 12), // Ajusta la altura según sea necesario
                    Text(
                      'Solicitar unirme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              if (user != null)
                Column(
                  crossAxisAlignment: alignment, // Mantén la alineación deseada
                  children: [
                    Text(
                      user.name ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Elo: ${user.elo ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              if (showQrOption)
                Column(
                  mainAxisSize: MainAxisSize.min, // Ajusta el tamaño del Column
                  children: [
                    const SizedBox(height: 9),
                    ElevatedButton.icon(
                      onPressed: _showInviteUserModal,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar invitación'),
                    ),
                    const SizedBox(height: 14), // Espacio entre los botones
                    ElevatedButton.icon(
                      onPressed: () => _showQrModal(context),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Mostrar QR'),
                    ),
                    const SizedBox(height: 9),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrModal(BuildContext context) {
    final qrData = match!.id ?? 'Datos no disponibles';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Código QR'),
          content: SizedBox(
            width: 200,
            height: 200,
            child: QrImageView(
              data:
                  qrData, // Aquí especificas el dato que quieres codificar en el QR
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchDetailsSection() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles del Partido',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Ubicación:', match!.location ?? 'Desconocida'),
            _buildDetailRow('Número de frames:', match!.frames.toString()),
            _buildDetailRow(
                'Fecha y Hora:', match!.matchDatetime ?? 'Desconocida'),
            _buildDetailRow('Público:', match!.public == true ? 'Sí' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(String title, User? user) {
    bool showSpots = false; // Mover la variable fuera del StatefulBuilder

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        // Verificar si lastMatchesInfo es null o vacío
        bool hasMatchesInfo = user?.lastMatchesInfo != null &&
            (user?.lastMatchesInfo?.isNotEmpty ?? false);

        return Card(
          elevation: 4.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: EloChart(
                    lastMatchesInfo: user?.lastMatchesInfo ?? [],
                    showSpots:
                        showSpots, // Pasamos el estado showSpots al EloChart
                  ),
                ),
                const SizedBox(height: 16),
                if (hasMatchesInfo) // Solo mostrar el botón si hay información
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showSpots =
                              !showSpots; // Cambia el estado de showSpots
                        });
                      },
                      child:
                          Text(showSpots ? 'Ocultar spots' : 'Mostrar spots'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
