import 'dart:io';

import 'package:dio/dio.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/user.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'package:snooker_flutter/services/mappers/user_mapper.dart';

class UsersService {
  static UsersService? _instance;

  static UsersService getInstance() {
    _instance ??= UsersService._();
    return _instance!;
  }

  UsersService._() {
    _initializeDio();
  }

  final Dio dio = Dio(BaseOptions(baseUrl: Environment.root));

  void _initializeDio() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await LoginService.getInstance().getToken();
          if (token != null) {
            options.headers['Authorization'] = token;
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Future<User> getMe() async {
    dynamic response;
    try {
      response = await dio.get('/users/get/me');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        return mapUser(data);
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

  Future<String> updateProfilePhoto(File photo) async {
    dynamic response;
    try {
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photo.path),
      });

      response = await dio.patch('/users/profile_photo/me', data: formData);
      if (response.statusCode == 200) {
        return 'Foto de perfil actualizada correctamente';
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

  Future<String> registerDeviceToken(String deviceToken) async {
    dynamic response;
    try {
      Map<String, dynamic> data = {'device_token': deviceToken};

      response = await dio.post('/add/device_token', data: data);
      if (response.statusCode == 200) {
        return 'Token del dispositivo registrado correctamente';
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

  Future<String> updateUser(
      {String? name, String? surname, String? bornDate, String? genre}) async {
    dynamic response;
    try {
      Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (surname != null) data['surname'] = surname;
      if (bornDate != null) data['born_date'] = bornDate;
      if (genre != null) data['genre'] = genre;

      response = await dio.patch('/users/update/me', data: data);
      if (response.statusCode == 200) {
        return 'Usuario actualizado correctamente';
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

  Future<String> sendEmailToResetPass(String email) async {
    dynamic response;
    try {
      response = await dio.post('/reset/pass', data: {'email': email});
      if (response.statusCode == 200) {
        return 'Email enviado correctamente';
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

  Future<String> changePassword(String oldPassword, String newPassword) async {
    dynamic response;
    try {
      response = await dio.post('/change/pass', data: {
        'old_pass': oldPassword,
        'new_pass': newPassword,
      });
      if (response.statusCode == 200) {
        return 'Contraseña cambiada correctamente';
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

  Future<dynamic> searchPlayer(String email) async {
    dynamic response;
    try {
      response = await dio.get('/users/$email');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        return mapUser(data);
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
}
