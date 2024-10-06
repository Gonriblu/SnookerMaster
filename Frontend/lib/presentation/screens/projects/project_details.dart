import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/project.dart';
import 'package:snooker_flutter/presentation/screens/projects/minimap_screen.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_plays_grid.dart';
import 'package:snooker_flutter/services/http_services/projects_datasource.dart';
import 'package:http/http.dart' as http;

class ProjectDetailsScreen extends StatefulWidget {
  static const name = 'project_screen';
  const ProjectDetailsScreen({super.key, required this.id});
  final String id;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  bool _isDataLoaded = false;
  Project? project;
  bool _isLoading = false;
  File? _imageFile;

  Future<void> _loadData() async {
    try {
      project = await ProjectService.getInstance().getProject(widget.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar el proyecto'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDataLoaded = true;
      });
    }
  }

  void _onPlayDeleted() {
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadMinimap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          '${Environment.root}/projects/${widget.id}/create_minimap'));

      if (response.statusCode == 200) {
        final Uint8List imageBytes =
            response.bodyBytes; // Obtiene los bytes de la imagen
        _showMinimapScreen(imageBytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al obtener el minimapa'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMinimapScreen(Uint8List imageBytes) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MinimapScreen(imageBytes: imageBytes),
      ),
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

    if (project == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error al cargar el proyecto.'),
        ),
      );
    }

    final imageUrl = project!.photo != null && project!.photo!.isNotEmpty
        ? '${Environment.root}/${project!.photo}'
        : 'https://via.placeholder.com/150';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoModal,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProject,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteProjectDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Información del proyecto
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen del proyecto
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Nombre y Fecha
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project!.name ?? 'Nombre no disponible',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              project?.date != null
                                  ? DateFormat('dd/MM/yyyy').format(
                                      DateTime.parse(project!
                                          .date!) // Convierte el String a DateTime
                                      )
                                  : 'Fecha no disponible',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Descripción del proyecto
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Descripción:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        project!.description ?? 'Descripción no disponible',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Botón para ir a la pantalla de estadísticas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      context.push('/projects/${widget.id}/statistics');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Ver Estadísticas'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _loadMinimap();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Ver Minimapa'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // CustomPlayGrid
              Expanded(
                child: CustomPlayGrid(
                  projectId: widget.id,
                  title: 'Tiros analizados',
                  playList: project!.plays ?? [],
                  onPlayDeleted: _onPlayDeleted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProject() async {
    String? newName = project!.name;
    String? newDescription = project!.description;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar proyecto'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: newName,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      onChanged: (value) {
                        newName = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: newDescription,
                      decoration:
                          const InputDecoration(labelText: 'Descripción'),
                      onChanged: (value) {
                        newDescription = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _selectPhoto(context, setState);
                          },
                          child: Row(
                            children: [
                              const Text(
                                'Cambiar foto',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                _imageFile == null
                                    ? Icons.add_circle_outline_outlined
                                    : Icons.photo,
                                size: 35,
                              ),
                            ],
                          ),
                        ),
                        if (_imageFile != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Image.file(
                              _imageFile!,
                              height: 50,
                              width: 50,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true; // Indicar que se está cargando
                          });
                          try {
                            final response = await ProjectService.getInstance()
                                .updateProject(widget.id,
                                    name: newName,
                                    description: newDescription,
                                    photo: _imageFile);
                            if (response == 'success') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Proyecto actualizado con éxito'),
                                ),
                              );
                              Navigator.of(context).pop();
                              _loadData(); // Actualizar datos del proyecto después de la edición
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error al actualizar el proyecto: $e'),
                              ),
                            );
                          } finally {
                            setState(() {
                              _isLoading =
                                  false; // Indicar que la carga ha terminado
                            });
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator() // Mostrar una rueda giratoria si se está cargando
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectPhoto(BuildContext context, StateSetter setState) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: const Text('¿Cómo deseas elegir la imagen?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Cerrar el AlertDialog
                await _pickImage(ImageSource.camera, setState);
              },
              child: const Text('Abrir cámara'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Cerrar el AlertDialog
                await _pickImage(ImageSource.gallery, setState);
              },
              child: const Text('Abrir galería'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, StateSetter setState) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _deleteProject() async {
    try {
      final response =
          await ProjectService.getInstance().deleteProject(widget.id);
      if (response == 'success') {
        Navigator.of(context)
            .pop(true); // Regresar a la pestaña anterior con valor true
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proyecto eliminado con éxito'),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar el modal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el proyecto: $e'),
        ),
      );
    }
  }

  void _showDeleteProjectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar proyecto'),
          content:
              const Text('¿Está seguro de que desea eliminar este proyecto?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _deleteProject(); // Llamar al servicio para eliminar el proyecto
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
