import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/config/fonts/text_styles.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';
import 'package:snooker_flutter/presentation/widgets/login/textfields/custom_textfield.dart';
import 'package:snooker_flutter/presentation/widgets/login/textfields/custom_password_textfield.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';

class LoginScreen extends StatefulWidget {
  static const name = 'login-screen';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
                    const Text('Email', style: TextStyles.form),
                    const Padding(padding: EdgeInsets.all(5)),
                    CustomTextField(textController: emailCtrl),
                    const SizedBox(height: 40),
                    const Text('Contraseña', style: TextStyles.form),
                    const Padding(padding: EdgeInsets.all(5)),
                    CustomPasswordTextField(passwordController: passCtrl),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                    GestureDetector(
                      child: const Text('He olvidado mi contraseña', style: TextStyles.form),
                      onTap: () {
                        context.go('/password_recovery');
                      },
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                    GestureDetector(
                      child: const Text('No tengo cuenta', style: TextStyles.form),
                      onTap: () {
                        context.go('/register');
                      },
                    ),
                    const Padding(padding: EdgeInsets.all(10)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          setState(() {
                            isLoading = true;
                          });
                          try {
                            final response = await LoginService.getInstance()
                                .login(emailCtrl.text, passCtrl.text);
                            if (response == 'success') {
                              context.go('/home/0', extra: {'shouldReloadData': true});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al hacer el login: $response'),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ha habido un error inesperado'),
                              ),
                            );
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Entrar'),
                      ),
                    ),
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
