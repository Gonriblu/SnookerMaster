import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/config/fonts/text_styles.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';
import 'package:snooker_flutter/presentation/widgets/login/textfields/custom_textfield.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';

class ResetPassCodeScreen extends StatefulWidget {
  static const name = 'reset-pass-code-screen';
  final String email;
  const ResetPassCodeScreen({super.key, required this.email});

  @override
  State<ResetPassCodeScreen> createState() => _ResetPassCodeScreenState();
}

class _ResetPassCodeScreenState extends State<ResetPassCodeScreen> {
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
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.only(top: 80)),
                const Text('SnookerMaster', style: TextStyles.header),
                const Padding(padding: EdgeInsets.only(top: 80)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Código', style: TextStyles.form),
                    const Padding(padding: EdgeInsets.all(5)),
                    CustomTextField(textController: codeCtrl),
                    const SizedBox(height: 40),
                    const Padding(padding: EdgeInsets.all(5)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    isLoading = true; // Habilitar estado de carga
                                  });
                                  try {
                                    final response = await LoginService.getInstance().checkPassCode(widget.email, codeCtrl.text);
                                    if (response == 'success') {
                                      context.go('/reset_pass/${widget.email}/${codeCtrl.text}');
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
                          child: Row(
                            children: [
                              const Text('Enviar'),
                              if (isLoading) const SizedBox(width: 10),
                              if (isLoading) const CircularProgressIndicator(),
                            ],
                          ),
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
