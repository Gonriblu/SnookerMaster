import 'package:dio/dio.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/services/http_services/login_service.dart';
import 'package:snooker_flutter/services/mappers/match_mapper.dart';
import 'package:snooker_flutter/entities/match.dart';

class MatchService {
  static MatchService? _instance;

  static MatchService getInstance() {
    _instance ??= MatchService._();
    return _instance!;
  }

  MatchService._() {
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

  Future<List<Match>> getMatches({
    bool? public,
    int? limit,
    int? offset,
    double? localMaxElo,
    double? localMinElo,
    DateTime? minDateTime,
    DateTime? maxDateTime,
    int? maxFrames,
    int? minFrames,
    double? latitude,
    double? longitude,
    bool? open,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (public != null) queryParams['public'] = public;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      if (localMaxElo != null) queryParams['local_max_elo'] = localMaxElo;
      if (localMinElo != null) queryParams['local_min_elo'] = localMinElo;
      if (minDateTime != null) queryParams['min_datetime'] = minDateTime;
      if (maxDateTime != null) queryParams['max_datetime'] = maxDateTime;
      if (maxFrames != null) queryParams['max_frames'] = maxFrames;
      if (minFrames != null) queryParams['min_frames'] = minFrames;
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (open != null) queryParams['open'] = open;
      queryParams['sort_by'] = 'match_datetime';
      queryParams['sort_direction'] = 'asc';

      final response = await dio.get('/matches/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return mapMatches(data);
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

  Future<List<Match>> getMyMatches({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      queryParams['sort_by'] = 'match_datetime';
      queryParams['sort_direction'] = 'desc';

      final response =
          await dio.get('/matches/my_matches', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return mapMatches(data);
        
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

  Future<Match> getMatch(String matchId) async {
    dynamic response;
    try {
      response = await dio.get('/matches/$matchId');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return mapMatch(data);
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

  Future<String> createMatch(String matchDatetime, String public, int frames,
      double latitude, double longitude, String formattedLocation) async {
    if (public.isEmpty || frames.isNaN) {
      return 'Complete todos los campos';
    }
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'match_datetime': matchDatetime,
        'public': public,
        'frames': frames,
        'latitude': latitude,
        'longitude': longitude,
        'formatted_location': formattedLocation,
      };
      response = await dio.post('/matches/new', data: data);
      if (response.statusCode == 200) {
        const dynamic data = 'Partida creada correctamente';
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

  Future<bool> deleteMatch(String matchId) async {
    try {

      final response =
          await dio.delete('/matches/$matchId');

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

  Future<String> sendResult(
      int localFrames, int visitorFrames, String matchId) async {
    if (localFrames.isNaN || visitorFrames.isNaN) {
      return 'Complete todos los campos';
    }
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'local_frames': localFrames,
        'visitor_frames': visitorFrames,
        'match_id': matchId,
      };
      response = await dio.post('/matches/result', data: data);
      if (response.statusCode == 200) {
        const dynamic data = 'Resultado enviado correctamente';
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

  Future<String> joinWithQr(String matchId) async {
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'match_id': matchId,
      };
      response = await dio.post('/matches/join_with_qr', data: data);
      if (response.statusCode == 200) {
        const dynamic data = 'Te has unido correctamente';
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

  Future<String> confirmResult(
      bool agreed, String matchId, int? localFrames, int? visitorFrames) async {
    if (!agreed) {
      return 'Complete todos los campos';
    }
    dynamic response;
    try {
      Map<String, dynamic> data = {
        'match_id': matchId,
        'agreed': agreed,
      };
      if (localFrames != null) data['local_frames'] = localFrames;
      if (visitorFrames != null) data['visitor_frames'] = visitorFrames;

      response = await dio.post('/matches/confirm_result', data: data);
      print('LA REPSONSEEEW');
      if (response.statusCode == 200) {
        const dynamic data = 'Enviado correctamente';
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
