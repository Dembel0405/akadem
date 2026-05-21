import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Ошибка сети. Проверьте подключение к интернету.']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Требуется авторизация']);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Нет прав доступа']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Ресурс не найден']);
}

class ValidationFailure extends Failure {
  final List<String> errors;
  const ValidationFailure(super.message, {this.errors = const []});

  @override
  List<Object?> get props => [message, errors];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Ошибка локального хранилища']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Произошла неизвестная ошибка']);
}
