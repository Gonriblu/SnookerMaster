import 'package:flutter/material.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController textController;

  const CustomTextField({super.key, required this.textController});

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: AppColor.white,
      keyboardType: TextInputType.emailAddress,
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
      controller: textController,
    );
  }
}
