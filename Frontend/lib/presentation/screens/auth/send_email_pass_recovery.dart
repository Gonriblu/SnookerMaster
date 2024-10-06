import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/config/fonts/text_styles.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';
import 'package:snooker_flutter/presentation/widgets/login/textfields/custom_textfield.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';

class SendEmailResetPassScreen extends StatefulWidget {
  static const name = 'send-email-reset-passscreen';
  const SendEmailResetPassScreen({super.key});

  @override
  State<SendEmailResetPassScreen> createState() => _SendEmailResetPassScreenState();
}

class _SendEmailResetPassScreenState extends State<SendEmailResetPassScreen> {
  final emailCtrl = TextEditingController();
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
                    const SizedBox(height: 25),
                    GestureDetector(
                      child: const Text('Volver al login',
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
                                  isLoading = true; // Habilitar estado de carga
                                });
                                try {
                                  final response = await LoginService.getInstance().sendCodeForNewPass(emailCtrl.text);
                                  if (response == 'success') {
                                    context.go('/confirm_pass_code/${emailCtrl.text}');
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al resetear: $e'),
                                    ),
                                  );
                                } finally {
                                  setState(() {
                                    isLoading = false; // Deshabilitar estado de carga
                                  });
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
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
