import 'dart:io';

import 'package:dio/dio.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/project.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'package:snooker_flutter/services/mappers/project_mapper.dart';

class ProjectService {
  static ProjectService? _instance;

  static ProjectService getInstance() {
    _instance ??= ProjectService._();
    return _instance!;
  }

  ProjectService._() {
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

  Future<List<Project>> getMyProjects(int? limit) async {
    dynamic response;
    try {
      String endpoint = '/projects/my_projects';
      if (limit != null) {
        endpoint += '?limit=$limit';
      }
      response = await dio.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return mapProjects(data);
      }else{
        throw Exception('Error en la solicitud');
      }
    } on DioException catch (error) {
      if (error.response != null) {
        throw Exception(error.response!.data['detail']);
      } else {
        throw Exception('Error del servidor');
      }
    }
  }

  Future<Project> getProject(String projectId) async {
    dynamic response;
    try {
      response = await dio.get('/projects/$projectId');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return mapProject(data);
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

  Future<String> createProject(
      String name, String description, File photo) async {
    if (name.isEmpty || description.isEmpty) {
      return 'Complete todos los campos';
    }
    dynamic response;
    try {
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photo.path),
        'name': name,
        'description': description,
      });
      response = await dio.post('/projects/new', data: formData);
      if (response.statusCode == 200) {
        const dynamic data = 'Proyecto creado correctamente';
        return (data);
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

  Future<String> updateProject(String projectId,
      {File? photo, String? name, String? description}) async {
    dynamic response;
    try {
      FormData formData = FormData();
      formData.fields.add(MapEntry('project_id', projectId));

      if (photo != null) {
        formData.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(photo.path, filename: 'photo.jpg'),
        ));
      }

      if (name != null) formData.fields.add(MapEntry('name', name));
      if (description != null) {
        formData.fields.add(MapEntry('description', description));
      }

      response = await dio.patch('/projects/update', data: formData);
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

  Future<String> deleteProject(String projectId) async {
    dynamic response;
    try {
      response = await dio.delete('/projects/delete/$projectId');
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
}
