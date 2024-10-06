import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/config/fonts/text_styles.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';
import 'package:snooker_flutter/presentation/widgets/login/textfields/custom_textfield.dart';
import 'package:snooker_flutter/presentation/widgets/login/textfields/custom_password_textfield.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';

class RegisterScreen extends StatefulWidget {
  static const name = 'register-screen';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final surnameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.green,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.only(top: 80)),
                const Text('SnookerMaster', style: TextStyles.header),
                const Padding(padding: EdgeInsets.only(top: 80)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre', style: TextStyles.form),
                    const Padding(padding: EdgeInsets.all(5)),
                    CustomTextField(textController: nameCtrl),
                    const SizedBox(height: 40),
                    const Text('Apellidos', style: TextStyles.form),
                    const Padding(padding: EdgeInsets.all(5)),
                    CustomTextField(textController: surnameCtrl),
                    const SizedBox(height: 40),
                    const Text('Email', style: TextStyles.form),
                    const Padding(padding: EdgeInsets.all(5)),
                    CustomTextField(textController: emailCtrl),
                    const SizedBox(height: 40),
                    const Text('Contraseña', style: TextStyles.form),
                    const Padding(padding: EdgeInsets.all(5)),
                    CustomPasswordTextField(passwordController: passCtrl),
                    const Padding(padding: EdgeInsets.all(5)),
                    GestureDetector(
                      child: const Text('Ya tengo una cuenta',
                          style: TextStyles.form),
                      onTap: () {
                        context.go('/login');
                      },
                    ),
                    const Padding(padding: EdgeInsets.all(5)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                setState(() {
                                  isLoading = true; // Iniciar estado de carga
                                });
                                try {
                                  final response =
                                      await LoginService.getInstance().register(
                                    nameCtrl.text,
                                    surnameCtrl.text,
                                    emailCtrl.text,
                                    passCtrl.text,
                                  );
                                  if (response == 'success') {
                                    context
                                        .go('/confirm_email/${emailCtrl.text}');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error al hacer el registro: $response'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Ha habido un error inexperado'),
                                    ),
                                  );
                                } finally {
                                  setState(() {
                                    isLoading =
                                        false; // Terminar estado de carga
                                  });
                                }
                              },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Enviar'),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
