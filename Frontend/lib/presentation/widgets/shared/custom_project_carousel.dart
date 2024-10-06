import 'package:flutter/material.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:snooker_flutter/services/http_services/projects_datasource.dart';

class CustomProjectCarousel extends StatefulWidget {
  final List<dynamic> itemsList;
  final double height;
  final String title;
  final VoidCallback? onProjectCreated;

  const CustomProjectCarousel({
    super.key,
    required this.itemsList,
    this.height = 200,
    required this.title,
    this.onProjectCreated,
  });

  @override
  State<CustomProjectCarousel> createState() => _CustomProjectCarouselState();
}

class _CustomProjectCarouselState extends State<CustomProjectCarousel> {
  bool _isSubmitting = false;
  File? _imageFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                if (widget.itemsList.isEmpty) {
                  _showCreateProjectDialog(context);
                } else {
                  context.push('/my_projects/details');
                }
              },
              child: Text(
                  widget.itemsList.isEmpty ? 'Crear Proyecto' : 'Ver Todos'),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        if (widget.itemsList.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No hay proyectos creados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          SizedBox(
            height: widget.height,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.itemsList.length,
              itemBuilder: (context, index) {
                final item = widget.itemsList[index];
                final imageUrl = item.photo != null && item.photo!.isNotEmpty
                    ? '${Environment.root}/${item.photo}'
                    : 'https://via.placeholder.com/150';

                return GestureDetector(
                  onTap: () {
                    context.push('/projects/${item.id}/details');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            imageUrl,
                            width: 150,
                            height: widget.height,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          top: 65,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: Colors.black.withOpacity(0.8),
                            ),
                            child: Center(
                              child: Text(
                                item.name!,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Método para mostrar el modal de creación de proyecto
  void _showCreateProjectDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear Nuevo Proyecto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _selectPhoto(context, setState);
                        },
                        child: Row(
                          children: [
                            const Text('Elegir foto',
                                style: TextStyle(fontSize: 16)),
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
              actions: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          _clearImage();
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_imageFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Por favor selecciona una imagen')),
                            );
                            return;
                          }
                          if (nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('El nombre es obligatorio')),
                            );
                            return; // Prevenir el envío si el nombre está vacío
                          }

                          // Validar descripción
                          if (descriptionController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('La descripción es obligatoria')),
                            );
                            return;
                          }

                          setState(() {
                            _isSubmitting = true;
                          });

                          String name = nameController.text;
                          String description = descriptionController.text;

                          try {
                            final response = await ProjectService.getInstance()
                                .createProject(
                              name,
                              description,
                              _imageFile!,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response)),
                            );
                            _clearImage();
                            Navigator.of(context).pop();
                            widget.onProjectCreated
                                ?.call(); // Llamar al callback
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Error al crear el proyecto: $e')),
                            );
                          } finally {
                            setState(() {
                              _isSubmitting = false;
                            });
                          }
                        },
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => _clearImage());
  }

  // Métodos para manejar la selección de imagen
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
                Navigator.pop(context);
                await _pickImage(ImageSource.camera, setState);
              },
              child: const Text('Abrir cámara'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
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

  void _clearImage() {
    setState(() {
      _imageFile = null;
    });
  }
}
