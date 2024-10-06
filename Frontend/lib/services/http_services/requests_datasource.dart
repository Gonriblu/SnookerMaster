import 'package:dio/dio.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/request_response.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'package:snooker_flutter/services/mappers/request_mapper.dart';

class RequestService {
  static RequestService? _instance;

  static RequestService getInstance() {
    _instance ??= RequestService._();
    return _instance!;
  }

  RequestService._() {
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

  Future<RequestsResponse> getMyRequests({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response =
          await dio.get('/requests/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return mapRequests(data);
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

  Future<String> requestJoin(String matchId) async {
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'match_id': matchId,
      };
      response = await dio.post('/requests/request-join', data: data);
      if (response.statusCode == 200) {
        const dynamic data = 'Invitación enviada correctamente';
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

  Future<String> invite(String matchId, String userId) async {
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'match_id': matchId,
        'user_id': userId,
      };
      response = await dio.post('/requests/invite', data: data);
      if (response.statusCode == 200) {
        const dynamic data = 'Invitación enviada correctamente';
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

  Future<bool> deleteRequest(String requestId) async {
    try {
      final response = await dio.delete('/requests/$requestId');

      if (response.statusCode == 200) {
        return true;
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

  Future<String> acceptRequest(String requestId) async {
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'request_id': requestId,
      };
      response = await dio.patch('/requests/accept', data: data);
      if (response.statusCode == 200) {
        const dynamic data = 'Invitación enviada correctamente';
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

  Future<String> rejectRequest(String requestId) async {
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'request_id': requestId,
      };
      response = await dio.patch('/requests/reject', data: data);
      if (response.statusCode == 200) {
        const dynamic data = 'Invitación enviada correctamente';
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
}
