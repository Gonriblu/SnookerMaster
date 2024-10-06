import 'package:flutter/material.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';

class CustomPasswordTextField extends StatelessWidget {
  final TextEditingController passwordController;

  const CustomPasswordTextField({super.key, required this.passwordController});

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: true, // password mode
      cursorColor: AppColor.white,
      keyboardType: TextInputType.visiblePassword,
      decoration: const InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.elliptical(10, 10)),
          borderSide: BorderSide(width: 1, color: AppColor.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.elliptical(10, 10)),
          borderSide: BorderSide(width: 1, color: AppColor.white),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.elliptical(10, 10)),
          borderSide: BorderSide(width: 1, color: AppColor.white),
        ),
      ),
      style: const TextStyle(color: AppColor.white),
      controller: passwordController,
    );
  }
}
