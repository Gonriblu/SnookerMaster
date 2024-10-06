import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/config/fonts/text_styles.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';
import 'package:snooker_flutter/presentation/widgets/login/textfields/custom_textfield.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';

class RegisterCodeScreen extends StatefulWidget {
  static const name = 'register-code-screen';
  final String email;
  const RegisterCodeScreen({super.key, required this.email});

  @override
  State<RegisterCodeScreen> createState() => _RegisterCodeScreenState();
}

class _RegisterCodeScreenState extends State<RegisterCodeScreen> {
  final codeCtrl = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColor.green,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(children: [
                      const Padding(padding: EdgeInsets.only(top: 80)),
                      const Text('SnookerMaster', style: TextStyles.header),
                      const Padding(padding: EdgeInsets.only(top: 80)),
                      const Text('Código', style: TextStyles.form),
                      const Padding(padding: EdgeInsets.all(5)),
                      CustomTextField(textController: codeCtrl),
                      const SizedBox(height: 40),
                      const Padding(padding: EdgeInsets.all(5)),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  try {
                                    final response =
                                        await LoginService.getInstance()
                                            .confirmEmail(
                                                widget.email, codeCtrl.text);
                                    if (response == 'success') {
                                      context.go('/login');
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al confirmar: $e'),
                                      ),
                                    );
                                  } finally {
                                    setState(() {
                                      isLoading =
                                          false; // Deshabilitar estado de carga
                                    });
                                  }
                                },
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : const Text('Enviar'),
                        ),
                      ]),
                    ])))));
  }
}
