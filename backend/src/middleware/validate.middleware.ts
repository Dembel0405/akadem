import { Request, Response, NextFunction } from 'express';
import { ZodSchema } from 'zod';

/**
 * Фабрика middleware для валидации тела запроса по Zod-схеме.
 * При ошибке бросает ZodError, который обрабатывает errorHandler.
 */
export function validateBody(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction) => {
    req.body = schema.parse(req.body);
    next();
  };
}

/**
 * Валидация query-параметров запроса.
 */
export function validateQuery(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction) => {
    req.query = schema.parse(req.query) as typeof req.query;
    next();
  };
}

/**
 * Валидация параметров URL (req.params).
 */
export function validateParams(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction) => {
    req.params = schema.parse(req.params) as typeof req.params;
    next();
  };
}
