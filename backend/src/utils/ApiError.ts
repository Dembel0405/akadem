/**
 * Базовый класс для ошибок API.
 * Используется в сервисах и middleware для стандартизации ответов об ошибках.
 */
export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly details?: unknown[];

  constructor(statusCode: number, message: string, code?: string, details?: unknown[]) {
    super(message);
    this.statusCode = statusCode;
    this.code = code ?? 'INTERNAL_ERROR';
    this.details = details;
    this.name = 'ApiError';
    // Восстанавливаем цепочку прототипов (необходимо при наследовании от Error в TS)
    Object.setPrototypeOf(this, ApiError.prototype);
  }

  static badRequest(message: string, details?: unknown[]) {
    return new ApiError(400, message, 'BAD_REQUEST', details);
  }

  static unauthorized(message = 'Необходима авторизация') {
    return new ApiError(401, message, 'UNAUTHORIZED');
  }

  static forbidden(message = 'Недостаточно прав доступа') {
    return new ApiError(403, message, 'FORBIDDEN');
  }

  static notFound(message = 'Ресурс не найден') {
    return new ApiError(404, message, 'NOT_FOUND');
  }

  static conflict(message: string) {
    return new ApiError(409, message, 'CONFLICT');
  }

  static validationError(message: string, details?: unknown[]) {
    return new ApiError(400, message, 'VALIDATION_ERROR', details);
  }

  static internal(message = 'Внутренняя ошибка сервера') {
    return new ApiError(500, message, 'INTERNAL_ERROR');
  }
}
