import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { ApiError } from '../utils/ApiError';

/**
 * Глобальный обработчик ошибок Express.
 * Перехватывает все ошибки, брошенные в контроллерах и сервисах,
 * и возвращает стандартизированный JSON-ответ.
 */
export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction): void {
  // Zod-ошибки валидации
  if (err instanceof ZodError) {
    res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Данные не прошли валидацию',
        details: err.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        })),
      },
    });
    return;
  }

  // Наши кастомные ApiError
  if (err instanceof ApiError) {
    res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
        ...(err.details && { details: err.details }),
      },
    });
    return;
  }

  // Prisma — ошибка уникальности
  if (err.constructor.name === 'PrismaClientKnownRequestError') {
    const prismaErr = err as { code?: string; meta?: { target?: string[] } };
    if (prismaErr.code === 'P2002') {
      const field = prismaErr.meta?.target?.[0] ?? 'поле';
      res.status(409).json({
        success: false,
        error: {
          code: 'CONFLICT',
          message: `Запись с таким значением "${field}" уже существует`,
        },
      });
      return;
    }
    if (prismaErr.code === 'P2025') {
      res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Запись не найдена' },
      });
      return;
    }
  }

  // Неизвестные ошибки — логируем и возвращаем 500
  console.error('[ERROR]', err.stack ?? err.message);

  const isDev = process.env.NODE_ENV === 'development';
  res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Внутренняя ошибка сервера',
      ...(isDev && { stack: err.stack }),
    },
  });
}
