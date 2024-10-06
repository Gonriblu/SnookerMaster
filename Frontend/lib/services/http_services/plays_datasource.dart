import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/play_statistics.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'package:snooker_flutter/services/mappers/plays_mapper.dart';

class PlaysService {
  static PlaysService? _instance;

  static PlaysService getInstance() {
    _instance ??= PlaysService._();
    return _instance!;
  }

  PlaysService._() {
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

  Future<String> createPlay(String projectId, String pocket, XFile video) async {
    dynamic response;
    try {
      FormData formData = FormData.fromMap({
        'video_file': await MultipartFile.fromFile(video.path),
        'pocket': pocket,
      });
      response =
          await dio.post('/projects/$projectId/new_play', data: formData);
      if (response.statusCode == 200) {
        const dynamic data = 'Jugada procesada correctamente';
        return (data);
      } else {
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

  Future<List<Play>> getMyPlays(int? limit) async {
    try {
      String endpoint = '/plays/my_plays';
      if (limit != null) {
        endpoint += '?limit=$limit';
      }
      final response = await dio.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return mapPlays(data);
      } else {
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

  Future<Play> getPlayDetails(String playId) async {
    dynamic response;
    try {
      response = await dio.get('/plays/$playId');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        return mapPlay(data);
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

  Future<String> deletePlay(String playId) async {
    dynamic response;
    try {
      final response = await dio.delete('/plays/$playId');
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
