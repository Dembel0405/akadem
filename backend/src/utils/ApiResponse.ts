import { Response } from 'express';

export interface PaginationMeta {
  total: number;
  page: number;
  perPage: number;
  totalPages: number;
}

/**
 * Утилиты для стандартизированных HTTP-ответов.
 * Все контроллеры должны использовать эти методы для единообразия API.
 */
export class ApiResponse {
  static success<T>(res: Response, data: T, message = 'Операция выполнена успешно', statusCode = 200) {
    return res.status(statusCode).json({
      success: true,
      message,
      data,
    });
  }

  static created<T>(res: Response, data: T, message = 'Запись успешно создана') {
    return ApiResponse.success(res, data, message, 201);
  }

  static paginated<T>(res: Response, data: T[], meta: PaginationMeta) {
    return res.status(200).json({
      success: true,
      data,
      meta,
    });
  }

  static noContent(res: Response) {
    return res.status(204).send();
  }

  static error(res: Response, statusCode: number, message: string, code?: string, details?: unknown[]) {
    return res.status(statusCode).json({
      success: false,
      error: {
        code: code ?? 'ERROR',
        message,
        ...(details && { details }),
      },
    });
  }
}

/**
 * Вычисляет параметры пагинации из query-параметров запроса.
 */
export function parsePagination(query: { page?: string; perPage?: string; limit?: string }) {
  const page = Math.max(1, parseInt(query.page ?? '1', 10));
  const perPage = Math.min(100, Math.max(1, parseInt(query.perPage ?? query.limit ?? '20', 10)));
  const skip = (page - 1) * perPage;

  return { page, perPage, skip };
}

export function buildPaginationMeta(total: number, page: number, perPage: number): PaginationMeta {
  return {
    total,
    page,
    perPage,
    totalPages: Math.ceil(total / perPage),
  };
}
