import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';
import 'package:snooker_flutter/presentation/widgets/shared/search_bar.dart';
import 'package:snooker_flutter/services/http_services/matches_datasources.dart';

class NewMatchScreen extends StatefulWidget {
  static const name = 'new-match-screen';
  const NewMatchScreen({super.key});

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _framesController = TextEditingController();
  String? _isPublic;
  double? selectedLatitude;
  double? selectedLongitude;
  String? formattedLocation;
  bool _isButtonEnabled = false;
  DateTime? _selectedDateTime;

  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _selectedDateTime = fullDateTime;

        final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
        final String formatted = formatter.format(fullDateTime);

        _dateTimeController.text = formatted;
        _updateButtonState();
      }
    }
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _formKey.currentState?.validate() == true &&
          selectedLatitude != null &&
          selectedLongitude != null &&
          _isPublic != null;
    });
  }

  Future<void> _submitForm() async {
    if (_isButtonEnabled) {
      final String matchDateTime = _selectedDateTime!.toUtc().toIso8601String();
      final frames = int.tryParse(_framesController.text) ?? 0;
      final isPublic = _isPublic ?? 'false';

      String response = await MatchService.getInstance().createMatch(
        matchDateTime,
        isPublic,
        frames,
        selectedLatitude!,
        selectedLongitude!,
        formattedLocation!,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response)));

      if (response == "Partido creada correctamente") {
        context.go("/home/1");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, complete todos los campos.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Crear Partido',
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.only(top: 30.0),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0)
                  .copyWith(bottom: 20.0),
              child: TextFormField(
                controller: _dateTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha y Hora',
                  hintText: 'Seleccione fecha y hora',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDateTime(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0)
                  .copyWith(bottom: 20.0),
              child: TextFormField(
                controller: _framesController,
                decoration: InputDecoration(
                  labelText: 'Número de Frames',
                  hintText: 'Ej: 5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final intValue = int.tryParse(value ?? '');
                  if (intValue != null && intValue.isEven) {
                    return 'Por favor, introduzca un número impar de frames';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0)
                  .copyWith(bottom: 10.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '¿Es público?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'true', child: Text('Sí')),
                  DropdownMenuItem(value: 'false', child: Text('No')),
                ],
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                    _updateButtonState();
                  });
                },
              ),
            ),
            SearchMapBar(
              onLocationSelected: (location) {
                setState(() {
                  selectedLatitude = location?.lat;
                  selectedLongitude = location?.lng;
                  formattedLocation = location?.formatted;
                  _updateButtonState();
                });
              },
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0)
                  .copyWith(top: 16.0),
              child: ElevatedButton(
                onPressed: _isButtonEnabled ? _submitForm : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Crear Partido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
