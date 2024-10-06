import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/config/fonts/text_styles.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';
import 'package:snooker_flutter/presentation/widgets/login/textfields/custom_password_textfield.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';

class ResetPassScreen extends StatefulWidget {
  static const name = 'reset-pass-screen';
  final String email;
  final String code;
  const ResetPassScreen({super.key, required this.email, required this.code});

  @override
  State<ResetPassScreen> createState() => _ResetPassScreenState();
}

class _ResetPassScreenState extends State<ResetPassScreen> {
  final passCtrl = TextEditingController();
  final repeatPassCtrl = TextEditingController();

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
                    const Text('Nueva contraseña', style: TextStyles.form),
                    const Padding(padding: EdgeInsets.all(5)),
                    CustomPasswordTextField(passwordController: passCtrl),
                    const SizedBox(height: 40),
                    const Text('Repita la contraseña', style: TextStyles.form),
                    const Padding(padding: EdgeInsets.all(5)),
                    CustomPasswordTextField(passwordController: repeatPassCtrl),
                    const Padding(padding: EdgeInsets.all(5)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    isLoading =
                                        true; // Habilitar estado de carga
                                  });
                                  try {
                                    final response =
                                        await LoginService.getInstance()
                                            .resetForgottenPass(
                                      widget.email,
                                      widget.code,
                                      passCtrl.text,
                                      repeatPassCtrl.text,
                                    );
                                    if (response == 'success') {
                                      context.go('/login');
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error al resetear contraseña: $e'),
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
                      ],
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
