import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:snooker_flutter/config/constants/environment.dart';

class LoginService {
  static LoginService? _instance;

  static LoginService getInstance() {
    _instance ??= LoginService._();
    return _instance!;
  }

  LoginService._();

  final storage = const FlutterSecureStorage();

  final Dio dio = Dio(BaseOptions(
    baseUrl: Environment.root,
  ));

  Future<dynamic> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Complete todos los campos';
    }
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'username': email,
        'password': password,
      };
      dio.options.contentType = Headers.formUrlEncodedContentType;
      response = await dio.post('/login', data: data);
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        saveEmail(email);
        saveToken(data);
        return 'success';
      }
    } on DioException catch (error) {
      if (error.response != null) {
        response = error.response!.data['detail'];
      } else {
        response = 'Error del servidor';
      }
    }
    return response;
  }

  Future<dynamic> logout() async {
    dynamic response;
    try {

      await storage.delete(key: 'email');
      await storage.delete(key: 'auth_token');

    } on DioException catch (error) {
      if (error.response != null) {
        response = error.response!.data['detail'];
      } else {
        response = 'Error del servidor';
      }
    }
    return response;
  }
  Future<String> register(
      String name, String surname, String email, String password) async {
    dynamic response;
    try {
      if (name.isEmpty ||
          surname.isEmpty ||
          email.isEmpty ||
          password.isEmpty) {
        return 'Complete todos los campos';
      }
      Map<String, dynamic> data = {
        'email': email,
        'name': name,
        'surname': surname,
        'password': password
      };
      response = await dio.post('/users/sign', data: data);
      if (response.statusCode == 200) {
        return 'success';
      }
    } on DioException catch (error) {
      if (error.response != null) {
        response = error.response!.data['detail'];
      } else {
        response = 'Error del servidor';
      }
    }
    return response;
  }

  Future<String> confirmEmail(String email, String code) async {
    if (email.isEmpty || code.isEmpty) {
      return 'Complete todos los campos';
    }
    dynamic response;
    try {
      Map<String, dynamic> data = {'email': email, 'code': code};

      response = await dio.post('/users/confirm_email', data: data);
      if (response.statusCode == 200) {
        return 'success';
      }
    } on DioException catch (error) {
      if (error.response != null) {
        response = error.response!.data['detail'];
      } else {
        response = 'Error del servidor';
      }
    }
    return response;
  }

  Future<String> sendCodeForNewPass(String email) async {
    if (email.isEmpty) {
      return 'Complete todos los campos';
    }
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'email': email,
      };

      response = await dio.post('/users/send_code_reset_pass', data: data);
      if (response.statusCode == 200) {
        return 'success';
      }
    } on DioException catch (error) {
      if (error.response != null) {
        response = error.response!.data['detail'];
      } else {
        response = 'Error del servidor';
      }
    }
    return response;
  }

  Future<String> checkPassCode(String email, String code) async {
    if (email.isEmpty || code.isEmpty) {
      return 'Complete todos los campos';
    }
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'email': email,
        'code': code,
      };

      response = await dio.post('/users/check_pass_code', data: data);
      if (response.statusCode == 200) {
        if (response.data == 'valid') {
          return 'success';
        } else {
          return 'codigo inválido';
        }
      }
    } on DioException catch (error) {
      if (error.response != null) {
        response = error.response!.data['detail'];
      } else {
        response = 'Error del servidor';
      }
    }
    return response;
  }

  Future<String> resetForgottenPass(
      String email, String code, String password, String newPassword) async {
    if (email.isEmpty ||
        code.isEmpty ||
        password.isEmpty ||
        newPassword.isEmpty) {
      return 'Complete todos los campos';
    }
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'email': email,
        'code': code,
        'new_pass': password,
        'confirmation_pass': newPassword,
      };

      response = await dio.post('/users/reset_pass', data: data);
      if (response.statusCode == 200) {
        return 'success';
      }
    } on DioException catch (error) {
      if (error.response != null) {
        response = error.response!.data['detail'];
      } else {
        response = 'Error del servidor';
      }
    }
    return response;
  }

  Future<void> saveToken(dynamic data) async {
    final token = 'Bearer ${data['access_token']}';
    await storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }
  
  Future<void> saveEmail(String email) async {
    await storage.write(key: 'email', value: email);
  }

  Future<String?> getEmail() async {
    return await storage.read(key: 'email');
  }

}
