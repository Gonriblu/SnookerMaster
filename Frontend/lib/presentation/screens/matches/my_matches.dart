import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';
import 'package:snooker_flutter/services/http_services/matches_datasources.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'package:snooker_flutter/entities/match.dart';
import 'package:intl/intl.dart';

class MyMatchesScreen extends StatefulWidget {
  static const name = 'my-matches-screen';
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Match>? pendingMatches;
  List<Match>? openMatches;
  List<Match>? completedMatches;

  String? userEmail;

  bool _isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _loadMatches();
  }

  Future<void> _loadUserEmail() async {
    userEmail = await LoginService.getInstance().getEmail();
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

  Future<void> _loadMatches() async {
    try {
      final matches = await MatchService.getInstance().getMyMatches(
        limit: null,
        offset: 0,
      );

      final now = DateTime.now();
      setState(() {
        pendingMatches = matches.where((match) {
          final matchDate = _parseMatchDatetime(match.matchDatetime);
          return matchDate != null &&
              matchDate.isAfter(now) &&
              match.cancelled != true;
        }).toList();

        openMatches = matches.where((match) {
          final matchDate = _parseMatchDatetime(match.matchDatetime);
          return matchDate != null &&
              matchDate.isBefore(now) &&
              match.visitor != null &&
              !(match.localResultAgreed == true &&
                  match.visitorResultAgreed == true) &&
              match.cancelled != true;
        }).toList();

        completedMatches = matches.where((match) {
          return (match.localResultAgreed == true &&
                  match.visitorResultAgreed == true) ||
              match.cancelled == true;
        }).toList();

        _isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage')),
      );
    }
  }

  Widget _buildMatchCard(BuildContext context, Match match,
      {required bool isCompleted,
      bool showDeleteButton = false,
      required bool showPendingAction}) {
    final bool isLocal = match.local?.email == userEmail;
    final bool isVisitor = match.visitor?.email == userEmail;

    String resultText = '';
    String opponentName;
    String opponentElo;
    String opponentPhoto;

    // Imagen predeterminada si no hay foto de perfil
    const String defaultProfilePhoto =
        'https://example.com/default_profile_photo.png'; // Cambia esta URL por la real
    opponentPhoto = match.visitor?.profilePhoto ?? defaultProfilePhoto;

    if (isLocal) {
      opponentName = match.visitor?.name ?? 'Sin rival';
      opponentElo = match.visitor?.elo.toString() ?? '-';
      opponentPhoto = match.visitor?.profilePhoto ?? defaultProfilePhoto;
      if (isCompleted) {
        if (match.cancelled == true) {
          resultText = 'Cancelado';
        } else if (match.localFrames! > match.visitorFrames!) {
          resultText = 'Ganaste';
        } else {
          resultText = 'Perdiste';
        }
      }
    } else if (isVisitor) {
      opponentName = match.local?.name ?? 'Sin rival';
      opponentElo = match.local?.elo.toString() ?? '-';
      opponentPhoto = match.local?.profilePhoto ?? defaultProfilePhoto;
      if (isCompleted) {
        if (match.cancelled == true) {
          resultText = 'Cancelado';
        } else if (match.visitorFrames! > match.localFrames!) {
          resultText = 'Ganaste';
        } else {
          resultText = 'Perdiste';
        }
      }
    } else {
      opponentName = 'Rival desconocido';
      opponentElo = '';
      opponentPhoto = defaultProfilePhoto;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (match.cancelled != true) {
                // Solo redirigir si el partido no ha sido cancelado
                context.push('/matches/${match.id}');
              } else {
                // Opcionalmente, podrías mostrar un mensaje indicando que el partido ha sido cancelado
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Este partido ha sido cancelado y no es accesible.')),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(opponentPhoto),
                    radius: 30.0,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.matchDatetime ?? 'Fecha no disponible',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(match.location ?? 'Ubicación no disponible'),
                        const SizedBox(height: 8.0),
                        Text('Frames: ${match.frames ?? 0}'),
                        const SizedBox(height: 8.0),
                        Text('Rival: $opponentName | ELO: $opponentElo'),
                        if (isCompleted && resultText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              resultText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                // Cambiar el color dependiendo del texto del resultado
                                color: resultText == 'Cancelado'
                                    ? Colors
                                        .blueAccent // Azul para partidos cancelados
                                    : resultText == 'Ganaste'
                                        ? Colors
                                            .green // Verde para partidos ganados
                                        : Colors
                                            .red, // Rojo para partidos perdidos
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        // Mostrar solo en "Sin Resultado"
                        if (!isCompleted &&
                            showPendingAction &&
                            match.visitor != null)
                          _buildPendingActionText(match, isLocal),
                      ],
                    ),
                  ),
                  Text(
                    match.distance ?? '',
                    style: const TextStyle(
                      fontSize: 19.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showDeleteButton)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmation(context, match);
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, Match match) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Partido'),
          content:
              const Text('¿Estás seguro de que quieres eliminar este partido?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // No eliminar
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmar eliminación
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await MatchService.getInstance().deleteMatch(match.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partido eliminado correctamente')),
        );
        _loadMatches(); // Recargar la lista de partidos
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el partido: $e')),
        );
      }
    }
  }

  Widget _buildPendingActionText(Match match, bool isLocal) {
    if (isLocal) {
      if (match.localResultAgreed == true &&
          match.visitorResultAgreed == false) {
        return const Text(
          'Esperando confirmación del rival',
          style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
        );
      } else if (match.localResultAgreed == false &&
          match.visitorResultAgreed == true) {
        return const Text(
          'Confirma el resultado puesto por el rival',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        );
      } else if (match.localResultAgreed == false &&
          match.visitorResultAgreed == false) {
        return const Text(
          'Pon un resultado',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        );
      }
    } else if (!isLocal) {
      if (match.visitorResultAgreed == true &&
          match.localResultAgreed == false) {
        return const Text(
          'Esperando confirmación del rival',
          style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
        );
      } else if (match.visitorResultAgreed == false &&
          match.localResultAgreed == true) {
        return const Text(
          'Confirma el resultado puesto por el rival',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        );
      } else if (match.visitorResultAgreed == false &&
          match.localResultAgreed == false) {
        return const Text(
          'Pon un resultado',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildMatchList(List<Match>? matches,
      {required bool isCompleted, required bool showPendingAction}) {
    if (matches == null || matches.isEmpty) {
      return const Center(
        child: Text('No hay partidos disponibles.'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildMatchCard(
          context,
          match,
          isCompleted: isCompleted,
          showDeleteButton:
              !isCompleted && pendingMatches?.contains(match) == true,
          showPendingAction:
              showPendingAction, // Aquí pasamos el nuevo parámetro
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Mis Partidos'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          elevation: 4.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16.0),
            ),
          ),
          title: const Text('Mis Partidos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Próximos"),
              Tab(text: "Sin Resultado"),
              Tab(text: "Terminados"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Próximos: No mostrar mensajes de acciones pendientes
            _buildMatchList(pendingMatches,
                isCompleted: false, showPendingAction: false),
            // Sin Resultado: Mostrar mensajes de acciones pendientes
            _buildMatchList(openMatches,
                isCompleted: false, showPendingAction: true),
            // Terminados: Mostrar resultados finales
            _buildMatchList(completedMatches,
                isCompleted: true, showPendingAction: false),
          ],
        ),
      ),
    );
  }
}
