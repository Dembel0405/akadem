import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';

// ==================== EVENTS ====================

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {}

// ==================== STATES ====================

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Dio _dio;

  AuthBloc() : _dio = dioClient.dio, super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    if (!tokenStorage.hasTokens) {
      emit(AuthUnauthenticated());
      return;
    }

    try {
      final response = await _dio.get(ApiConstants.me);
      final user = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
      emit(AuthAuthenticated(user));
    } catch (_) {
      await tokenStorage.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': event.email, 'password': event.password},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;

      await tokenStorage.saveTokens(
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String,
      );

      final user = UserModel.fromJson(userJson);
      emit(AuthAuthenticated(user));
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] as String? ?? 'Ошибка входа';
      emit(AuthError(message));
    } catch (_) {
      emit(const AuthError('Произошла непредвиденная ошибка'));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    final refreshToken = tokenStorage.getRefreshToken();
    try {
      if (refreshToken != null) {
        await _dio.post(ApiConstants.logout, data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Ошибки при logout игнорируем — всё равно очищаем локальные данные
    }

    await tokenStorage.clear();
    emit(AuthUnauthenticated());
  }
}
