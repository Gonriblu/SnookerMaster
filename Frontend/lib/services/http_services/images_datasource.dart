import 'package:dio/dio.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/snooker_image.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'package:snooker_flutter/services/mappers/snooker_images_mapper.dart';

class SnookerImageService  {

  static SnookerImageService? _instance;

  static SnookerImageService getInstance() {
    _instance ??= SnookerImageService._();
    return _instance!;
  }

  SnookerImageService._(){
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
  
  Future<List<SnookerImage>> getMySnookerImages() async {
    final response = await dio.get('/images/my_images');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return mapSnookerImages(data);
    } else {
      throw Exception('Failed to load my images');
    }
  }
}
