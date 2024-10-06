import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/play_statistics.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/presentation/widgets/shared/select_pocket.dart';
import 'package:snooker_flutter/services/http_services/plays_datasource.dart';

class CustomPlayGrid extends StatefulWidget {
  final String title;
  final List<Play> playList;
  final String projectId;
  final VoidCallback onPlayDeleted;

  const CustomPlayGrid({
    super.key,
    required this.title,
    required this.projectId,
    required this.playList,
    required this.onPlayDeleted,
  });

  @override
  State<CustomPlayGrid> createState() => _CustomPlayGridState();
}

class _CustomPlayGridState extends State<CustomPlayGrid> {
  XFile? _videoFile;
  String? _selectedPocket; // Tronera seleccionada
  bool _isDeleting = false;

  // Mapa para mostrar etiquetas en español
  final Map<String, String> pocketLabels = {
    'TopLeft': 'Tronera superior izquierda',
    'TopRight': 'Tronera superior derecha',
    'MediumLeft': 'Tronera medio izquierda',
    'MediumRight': 'Tronera medio derecha',
    'BottomLeft': 'Tronera inferior izquierda',
    'BottomRight': 'Tronera inferior derecha',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10.0),
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: widget.playList.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: () {
                    _showUploadPlayDialog(context);
                  },
                  child: Card(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.add, size: 50, color: Colors.black),
                    ),
                  ),
                );
              } else {
                final play = widget.playList[index - 1];
                final imageUrl = play.photo != null && play.photo!.isNotEmpty
                    ? '${Environment.root}/${play.photo}'
                    : 'https://via.placeholder.com/150';
                return GestureDetector(
                  onTap: () {
                    context.push('/plays/${play.id}/details');
                  },
                  child: Card(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              _showDeleteConfirmationDialog(context, play.id!);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Color.fromARGB(255, 212, 79, 69),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showUploadPlayDialog(BuildContext context) {
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Analizar nueva jugada'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _selectVideo(context, setState);
                      },
                      child: Row(
                        children: [
                          const Text(
                            'Elegir video',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            _videoFile == null
                                ? Icons.add_circle_outline_outlined
                                : Icons.photo,
                            size: 35,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Mostrar tronera seleccionada
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SelectPocketScreen(),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _selectedPocket = result;
                      });
                    }
                  },
                  child: const Text('Seleccionar tronera'),
                ),
                const SizedBox(height: 20),
                if (_selectedPocket != null)
                  Text(
                    'Tronera seleccionada: ${pocketLabels[_selectedPocket!] ?? 'Desconocida'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                else
                  const Text(
                    'No se ha seleccionado ninguna tronera.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
              ]),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearVideo();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_videoFile == null || _selectedPocket == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Selecciona un video y una tronera antes de enviar.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop();
                    await _createPlay(scaffoldContext);
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => _clearVideo());
  }

  Future<void> _createPlay(BuildContext context) async {
    if (_videoFile == null || _selectedPocket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un video y una tronera antes de enviar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('El video está siendo procesado'),
            ],
          ),
        );
      },
    );

    try {
      final response = await PlaysService.getInstance().createPlay(
        widget.projectId,
        _selectedPocket!, 
        _videoFile!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la jugada: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      Navigator.of(context).pop();
    }

    _clearVideo();
  }

  Future<void> _selectVideo(BuildContext context, StateSetter setState) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar video'),
          content: const Text('¿Cómo deseas elegir el video?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _pickVideo(ImageSource.camera, setState);
              },
              child: const Text('Abrir cámara'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _pickVideo(ImageSource.gallery, setState);
              },
              child: const Text('Abrir galería'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickVideo(ImageSource source, StateSetter setState) async {
    final XFile? video =
        await ImagePicker().pickVideo(source: source);
    setState(() {
      _videoFile = video;
    });
  }

  void _clearVideo() {
    setState(() {
      _videoFile = null;
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context, String playId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Eliminar jugada'),
              content:
                  const Text('¿Está seguro de que desea eliminar esta jugada?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isDeleting
                      ? null
                      : () async {
                          setState(() {
                            _isDeleting = true;
                          });

                          await _deletePlay(playId, context);

                          setState(() {
                            _isDeleting = false;
                          });
                        },
                  child: _isDeleting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePlay(String playId, BuildContext context) async {
    try {
      final response = await PlaysService.getInstance().deletePlay(playId);
      if (response == 'success') {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jugada eliminada con éxito'),
          ),
        );
        setState(() {
          widget.playList.removeWhere((play) => play.id == playId);
        });
        widget.onPlayDeleted();
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la jugada: $e'),
        ),
      );
    }
  }
}
