import { ApiError } from '../../src/utils/ApiError';

// Мокируем prisma и bcrypt, чтобы тесты не требовали реальной БД
jest.mock('../../src/config/database', () => ({
  default: {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    refreshToken: {
      create: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
      deleteMany: jest.fn(),
    },
  },
}));

jest.mock('bcrypt', () => ({
  compare: jest.fn(),
  hash: jest.fn(),
}));

import prisma from '../../src/config/database';
import bcrypt from 'bcrypt';
import { AuthService } from '../../src/modules/auth/auth.service';

const authService = new AuthService();

describe('AuthService', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('login', () => {
    it('должен выбрасывать 401, если пользователь не найден', async () => {
      (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(authService.login({ email: 'x@x.com', password: '123' })).rejects.toThrow(
        ApiError,
      );
    });

    it('должен выбрасывать 401, если пользователь деактивирован', async () => {
      (prisma.user.findUnique as jest.Mock).mockResolvedValue({
        id: '1',
        email: 'x@x.com',
        isActive: false,
        passwordHash: 'hash',
        role: 'STUDENT',
      });

      await expect(authService.login({ email: 'x@x.com', password: '123' })).rejects.toThrow(
        ApiError,
      );
    });

    it('должен выбрасывать 401 при неверном пароле', async () => {
      (prisma.user.findUnique as jest.Mock).mockResolvedValue({
        id: '1',
        email: 'x@x.com',
        isActive: true,
        passwordHash: 'hash',
        role: 'STUDENT',
      });
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(authService.login({ email: 'x@x.com', password: 'wrong' })).rejects.toThrow(
        ApiError,
      );
    });

    it('должен возвращать токены и данные пользователя при успешном входе', async () => {
      const mockUser = {
        id: 'user-id-1',
        email: 'admin@college.kz',
        isActive: true,
        passwordHash: 'hash',
        role: 'ADMIN',
        firstName: 'Admin',
        lastName: 'User',
        avatar: null,
      };

      (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);
      (prisma.refreshToken.create as jest.Mock).mockResolvedValue({});

      const result = await authService.login({ email: 'admin@college.kz', password: 'Admin123!' });

      expect(result.tokens.accessToken).toBeDefined();
      expect(result.tokens.refreshToken).toBeDefined();
      expect(result.user.email).toBe('admin@college.kz');
    });
  });

  describe('register', () => {
    it('должен выбрасывать 409, если email уже занят', async () => {
      (prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 'existing' });

      await expect(
        authService.register({
          email: 'exists@x.com',
          password: 'Test123!',
          firstName: 'Test',
          lastName: 'User',
          role: 'STUDENT',
        }),
      ).rejects.toThrow(ApiError);
    });
  });
});

describe('ApiError', () => {
  it('unauthorized() должен возвращать статус 401', () => {
    const err = ApiError.unauthorized();
    expect(err.statusCode).toBe(401);
    expect(err.code).toBe('UNAUTHORIZED');
  });

  it('forbidden() должен возвращать статус 403', () => {
    const err = ApiError.forbidden();
    expect(err.statusCode).toBe(403);
  });

  it('notFound() должен возвращать статус 404', () => {
    const err = ApiError.notFound();
    expect(err.statusCode).toBe(404);
  });

  it('conflict() должен возвращать статус 409', () => {
    const err = ApiError.conflict('Дубликат');
    expect(err.statusCode).toBe(409);
  });
});
