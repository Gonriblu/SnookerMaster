import 'package:dio/dio.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/general_statistic.dart';
import 'package:snooker_flutter/entities/project_statistics.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'package:snooker_flutter/services/mappers/statistics_mapper.dart';

class StatisticsService {
  static StatisticsService? _instance;

  static StatisticsService getInstance() {
    _instance ??= StatisticsService._();
    return _instance!;
  }

  StatisticsService._() {
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

  Future<GeneralStatistics> getMyGeneralStatistics() async {
    dynamic response;
    try {
      response = await dio.get('/statistics/my_general_statistics');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        return mapGeneralStatistics(data);
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

  Future<ProjectStatistics> getProjectStatistics(String projectId) async {
    dynamic response;
    try {
      response = await dio.get('/statistics/projects/$projectId');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        return mapProjectStatistics(data);
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
