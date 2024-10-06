import 'package:flutter/material.dart';
import 'package:snooker_flutter/entities/request.dart';
import 'package:snooker_flutter/services/http_services/requests_datasource.dart';

class MyRequestScreen extends StatefulWidget {
  static const name = 'my-requests-screen';
  const MyRequestScreen({super.key});

  @override
  State<MyRequestScreen> createState() => MyRequestsScreenState();
}

class MyRequestsScreenState extends State<MyRequestScreen> {
  List<Request> sentInvitations = [];
  List<Request> receivedInvitations = [];

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    try {
      final requestsResponse =
          await RequestService.getInstance().getMyRequests();
      setState(() {
        sentInvitations = requestsResponse.sentRequests;
        receivedInvitations = requestsResponse.receivedRequests;
      });
    } catch (e) {
      print("Error loading invitations: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Número de pestañas
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          elevation: 4.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16.0),
            ),
          ),
          title: const Text("Mis Invitaciones"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Enviadas"),
              Tab(text: "Recibidas"),
              Tab(text: "Respondidas"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInvitationsList("Enviadas"),
            _buildInvitationsList("Recibidas"),
            _buildInvitationsList("Respondidas"),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationsList(String selectedTab) {
    List<Map<String, dynamic>> filteredInvitations = [];

    switch (selectedTab) {
      case "Enviadas":
        filteredInvitations = sentInvitations
            .where((request) => request.status == "Pendiente")
            .map((request) => {"request": request, "type": "Enviada"})
            .toList();
        break;
      case "Recibidas":
        filteredInvitations = receivedInvitations
            .where((request) => request.status == "Pendiente")
            .map((request) => {"request": request, "type": "Recibida"})
            .toList();
        break;
      case "Respondidas":
        filteredInvitations = [
          ...sentInvitations
              .where((request) => request.status != "Pendiente")
              .map((request) => {"request": request, "type": "Enviada"}),
          ...receivedInvitations
              .where((request) => request.status != "Pendiente")
              .map((request) => {"request": request, "type": "Recibida"})
        ];
        break;
      default:
        filteredInvitations = [];
    }

    if (filteredInvitations.isEmpty) {
      return const Center(child: Text("No hay invitaciones en esta sección"));
    }

    return ListView.builder(
      itemCount: filteredInvitations.length,
      itemBuilder: (context, index) {
        final invitationData = filteredInvitations[index];
        final request = invitationData['request'] as Request;
        final invitationType = invitationData['type'] as String;

        return _buildInvitationCard(
            context, request, invitationType, selectedTab);
      },
    );
  }

  Widget _buildInvitationCard(BuildContext context, Request request,
      String invitationType, String selectedTab) {
    final player =
        invitationType == "Enviada" ? request.receiver : request.inviter;

    final bool isAccepted = request.status == "Aceptada";
    final Color statusColor =
        isAccepted ? Colors.green[100]! : Colors.red[100]!;
    final IconData statusIcon = isAccepted ? Icons.check_circle : Icons.cancel;
    final String statusText = isAccepted ? "Aceptada" : "Rechazada";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          // Define una acción aquí si deseas que la tarjeta sea interactiva
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              if (selectedTab == "Respondidas")
                Positioned(
                  top: 0.0,
                  right: 0.0,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: Colors.white, size: 16.0),
                        const SizedBox(width: 4.0),
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(player?.profilePhoto ?? ''),
                    radius: 30.0,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jugador:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                            '${player?.name ?? "Desconocido"} | Elo: ${player?.elo ?? "N/A"}'),
                        const SizedBox(height: 16.0),
                        const Text(
                          'Partido:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                            'Fecha: ${request.match?.matchDatetime ?? "No disponible"}'),
                        const SizedBox(height: 4.0),
                        Text(
                            'Ubicación: ${request.match?.location ?? "No disponible"}'),
                        const SizedBox(height: 4.0),
                        Text('Frames: ${request.match?.frames ?? 0}'),
                        const SizedBox(height: 8.0),
                        Text(
                          'Enviada el ${request.requestDatetime ?? 'No especificada'}',
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (selectedTab == "Recibidas" &&
                            request.status == "Pendiente") ...[
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[100],
                                ),
                                onPressed: () => _showConfirmationDialog(
                                    context, request, false),
                                child: const Text("Rechazar"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[100],
                                ),
                                onPressed: () => _showConfirmationDialog(
                                    context, request, true),
                                child: const Text("Aceptar"),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (selectedTab == "Enviadas") // Botón de borrar en "Enviadas"
                Positioned(
                  top: 0.0,
                  right: 0.0,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(context, request),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, Request request, bool isAccept) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(isAccept ? '¿Aceptar invitación?' : '¿Rechazar invitación?'),
          content: Text(isAccept
              ? '¿Seguro que quieres aceptar esta invitación?'
              : '¿Seguro que quieres rechazar esta invitación?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (isAccept) {
                  await _acceptRequest(request.id);
                } else {
                  await _rejectRequest(request.id);
                }
              },
              child: Text(isAccept ? 'Sí' : 'Sí'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Request request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Eliminar invitación?'),
          content: const Text(
              '¿Estás seguro de que deseas eliminar esta invitación enviada?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteRequest(request.id);
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRequest(String? requestId) async {
    try {
      await RequestService.getInstance().deleteRequest(requestId!);
      _loadInvitations(); // Recargar la lista de invitaciones
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la invitación: $e')),
      );
    }
  }

  Future<void> _acceptRequest(String? requestId) async {
    try {
      await RequestService.getInstance().acceptRequest(requestId!);
      _loadInvitations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar la invitación: $e')),
      );
    }
  }

  Future<void> _rejectRequest(String? requestId) async {
    try {
      await RequestService.getInstance().rejectRequest(requestId!);
      _loadInvitations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar la invitación: $e')),
      );
    }
  }
}
