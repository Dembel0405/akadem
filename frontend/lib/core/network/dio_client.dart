import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import '../errors/failures.dart';

/// Настроенный Dio-клиент с JWT-интерсептором и обработкой ошибок.
class DioClient {
  late final Dio _dio;
  bool _isRefreshing = false;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_dio));
  }

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;

  _AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Пробуем обновить токен
      final refreshToken = tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
          final response = await refreshDio.post(
            ApiConstants.refresh,
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = response.data['data']['accessToken'] as String;
          final newRefreshToken = response.data['data']['refreshToken'] as String?;

          await tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );

          // Повторяем оригинальный запрос с новым токеном
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          // Refresh упал — очищаем токены (пользователь будет перенаправлен на login)
          await tokenStorage.clear();
        }
      }
    }

    handler.next(err);
  }
}

/// Преобразует DioException в Failure для BLoC.
Failure dioErrorToFailure(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError) {
    return const NetworkFailure();
  }

  final statusCode = e.response?.statusCode;
  final message = e.response?.data?['error']?['message'] as String? ?? 'Произошла ошибка';

  switch (statusCode) {
    case 400:
      return ValidationFailure(message);
    case 401:
      return const UnauthorizedFailure();
    case 403:
      return const ForbiddenFailure();
    case 404:
      return NotFoundFailure(message);
    case 409:
      return ServerFailure(message, statusCode: 409);
    default:
      return ServerFailure(message, statusCode: statusCode);
  }
}

final dioClient = DioClient();
