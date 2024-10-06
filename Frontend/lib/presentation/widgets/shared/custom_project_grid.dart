import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/project.dart';
import 'package:snooker_flutter/services/http_services/projects_datasource.dart';

class CustomProjectGrid extends StatefulWidget {
  final bool create;
  final String? title;
  final String to;
  final List<Project> projectList;
  final VoidCallback? onProjectCreated;

  const CustomProjectGrid({
    super.key,
    required this.create,
    this.title,
    required this.to,
    required this.projectList,
    this.onProjectCreated,
  });

  @override
  State<CustomProjectGrid> createState() => _CustomProjectGridState();
}

class _CustomProjectGridState extends State<CustomProjectGrid> {
  File? _imageFile;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 10.0),
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: widget.create
                ? widget.projectList.length + 1
                : widget.projectList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (widget.create && index == 0) {
                return GestureDetector(
                  onTap: () {
                    _showCreateProjectDialog(context);
                  },
                  child: Card(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.add, size: 50, color: Colors.black),
                    ),
                  ),
                );
              } else {
                final adjustedIndex = widget.create ? index - 1 : index;
                final project = widget.projectList[adjustedIndex];
                final name = project.name ?? 'Error';
                final imageUrl =
                    project.photo != null && project.photo!.isNotEmpty
                        ? '${Environment.root}/${project.photo}'
                        : 'https://via.placeholder.com/150';
                return GestureDetector(
                  onTap: () async {
                    final result = await context
                        .push('/projects/${project.id}/${widget.to}');
                    if (result == true) {
                      setState(() {
                        widget.projectList.removeAt(adjustedIndex);
                      });
                    }
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
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 5.0,
                              horizontal: 4.0,
                            ),
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
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
                            return; // Prevenir el envío si la descripción está vacía
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

  void _clearImage() {
    setState(() {
      _imageFile = null;
    });
  }
}
