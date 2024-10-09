import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/entities/user.dart';
import 'package:snooker_flutter/presentation/widgets/shared/elo_chart.dart';
import 'package:snooker_flutter/services/http_services/users_service.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isDataLoaded = false;
  bool _isUpdating = false;
  bool _isSubmitting = false;
  User? myUser;
  File? _imageFile;

  Future<void> _loadData() async {
    try {
      String? token = await LoginService.getInstance().getToken();
      if (token != null) {
        myUser = await UsersService.getInstance().getMe();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los datos del usuario: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (!_isDataLoaded) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      _loadData();
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        automaticallyImplyLeading: true,
        elevation: 4.0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16.0),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: GestureDetector(
              onTap: () {
                _showChangeProfileImageDialog(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: myUser?.profilePhoto != null
                      ? NetworkImage(myUser!.profilePhoto!)
                      : const NetworkImage('https://via.placeholder.com/150'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildUserInfoItem('Nombre', myUser?.name ?? 'Nombre no disponible'),
          _buildUserInfoItem(
              'Apellidos', myUser?.surname ?? 'Apellidos no disponibles'),
          _buildUserInfoItem('Correo', myUser?.email ?? 'Correo no disponible'),
          _buildUserInfoItem(
              'Fecha de Nacimiento',
              myUser?.bornDate != null
                  ? _formatDate(myUser!.bornDate!)
                  : 'Fecha de nacimiento no disponible'),
          _buildUserInfoItem('Género', myUser?.genre ?? 'Género no disponible'),
          const SizedBox(height: 20),
          _buildStatisticsCard('Mis últimos partidos', myUser),
        ],
      ),
    );
  }

  Widget _buildUserInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(String title, User? user) {
    bool showSpots = false; // Mover la variable fuera del StatefulBuilder

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
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
                    showSpots: showSpots,
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

  void _showEditProfileModal(BuildContext context) {
    TextEditingController nameController =
        TextEditingController(text: myUser?.name);
    TextEditingController surnameController =
        TextEditingController(text: myUser?.surname);
    TextEditingController bornDateController =
        TextEditingController(text: myUser?.bornDate);
    String? selectedGender = myUser?.genre;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Editar Perfil'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: surnameController,
                      decoration: const InputDecoration(labelText: 'Apellidos'),
                    ),
                    TextField(
                      controller: bornDateController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                bornDateController.text = pickedDate
                                    .toIso8601String()
                                    .split('T')
                                    .first;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: const InputDecoration(labelText: 'Género'),
                      items: <String>['Hombre', 'Mujer', 'Otro']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedGender = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: _isUpdating
                      ? null
                      : () async {
                          setState(() {
                            _isUpdating = true;
                          });
                          await _updateUserProfile(
                            nameController.text,
                            surnameController.text,
                            bornDateController.text,
                            selectedGender ?? '',
                          );
                          setState(() {
                            _isUpdating = false;
                          });
                          Navigator.of(context).pop();
                        },
                  child: _isUpdating
                      ? const CircularProgressIndicator()
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateUserProfile(
      String name, String surname, String bornDate, String genre) async {
    try {
      String response = await UsersService.getInstance().updateUser(
        name: name,
        surname: surname,
        bornDate: bornDate,
        genre: genre,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response)),
      );
      await _loadData(); // Recargar los datos del usuario después de la actualización
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el perfil: $e')),
      );
    }
  }

  void _showChangeProfileImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cambiar foto de perfil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _selectPhoto(context, setState);
                        },
                        child: Row(
                          children: [
                            const Text(
                              'Elegir foto',
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              _imageFile!,
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
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
                          Navigator.of(context).pop(); // Cerrar el diálogo
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() {
                            _isSubmitting = true;
                          });
                          try {
                            final response = await UsersService.getInstance()
                                .updateProfilePhoto(_imageFile!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response)),
                            );
                            _clearImage();
                            await _loadData(); // Recargar los datos del usuario después de la actualización
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Error al cambiar la foto: $e')),
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
    ).then(
        (_) => _clearImage()); // Ensure image is cleared when dialog is closed.
  }

  String _formatDate(String bornDate) {
    try {
      DateTime parsedDate = DateTime.parse(bornDate);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Fecha no válida';
    }
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

  Future<void> _logout() async {
    try {
      await LoginService.getInstance().logout();
      if (mounted) {
        context.go('/login');
      }
      setState(() {
        _isDataLoaded = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }
}
