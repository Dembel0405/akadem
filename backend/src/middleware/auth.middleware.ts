import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Role } from '@prisma/client';
import { jwtConfig } from '../config/jwt';
import { ApiError } from '../utils/ApiError';

interface JwtPayload {
  id: string;
  email: string;
  role: Role;
}

/**
 * Верифицирует JWT access-токен из заголовка Authorization.
 * Прикрепляет decoded payload к req.user.
 */
export function authenticate(req: Request, _res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    throw ApiError.unauthorized('Токен авторизации отсутствует');
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, jwtConfig.accessSecret) as JwtPayload;
    req.user = { id: decoded.id, email: decoded.email, role: decoded.role };
    next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw ApiError.unauthorized('Токен авторизации истёк');
    }
    throw ApiError.unauthorized('Недействительный токен авторизации');
  }
}

/**
 * Проверяет, что авторизованный пользователь имеет одну из указанных ролей.
 * Используется после middleware authenticate.
 */
export function authorize(...roles: Role[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) {
      throw ApiError.unauthorized();
    }

    if (!roles.includes(req.user.role)) {
      throw ApiError.forbidden(`Доступ разрешён только для ролей: ${roles.join(', ')}`);
    }

    next();
  };
}
