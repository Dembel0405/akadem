import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import prisma from '../../config/database';
import { jwtConfig } from '../../config/jwt';
import { ApiError } from '../../utils/ApiError';
import type { LoginDto, RegisterDto, RefreshDto } from './auth.schema';

interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

interface UserPayload {
  id: string;
  email: string;
  role: string;
  firstName: string;
  lastName: string;
  avatar: string | null;
}

function generateTokenPair(userId: string, email: string, role: string): TokenPair {
  const payload = { id: userId, email, role };

  const accessToken = jwt.sign(payload, jwtConfig.accessSecret, {
    expiresIn: jwtConfig.accessExpiresIn,
  } as jwt.SignOptions);

  const refreshToken = jwt.sign(
    { id: userId, jti: uuidv4() }, // jti уникален для каждого токена
    jwtConfig.refreshSecret,
    { expiresIn: jwtConfig.refreshExpiresIn } as jwt.SignOptions,
  );

  return { accessToken, refreshToken };
}

function parseRefreshExpiry(): Date {
  const expiresIn = jwtConfig.refreshExpiresIn;
  const match = expiresIn.match(/^(\d+)([smhd])$/);
  if (!match) return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  const value = parseInt(match[1], 10);
  const unit = match[2];
  const multipliers: Record<string, number> = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
  return new Date(Date.now() + value * multipliers[unit]);
}

export class AuthService {
  async login(dto: LoginDto): Promise<{ tokens: TokenPair; user: UserPayload }> {
    const user = await prisma.user.findUnique({ where: { email: dto.email } });

    if (!user || !user.isActive) {
      throw ApiError.unauthorized('Неверный email или пароль');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw ApiError.unauthorized('Неверный email или пароль');
    }

    const tokens = generateTokenPair(user.id, user.email, user.role);

    // Сохраняем refresh-токен в БД для возможности инвалидации
    await prisma.refreshToken.create({
      data: {
        token: tokens.refreshToken,
        userId: user.id,
        expiresAt: parseRefreshExpiry(),
      },
    });

    return {
      tokens,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        firstName: user.firstName,
        lastName: user.lastName,
        avatar: user.avatar,
      },
    };
  }

  async register(dto: RegisterDto): Promise<UserPayload> {
    const exists = await prisma.user.findUnique({ where: { email: dto.email } });
    if (exists) {
      throw ApiError.conflict('Пользователь с таким email уже существует');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const user = await prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
        firstName: dto.firstName,
        lastName: dto.lastName,
        middleName: dto.middleName,
        role: dto.role as any,
        phone: dto.phone,
        studentGroupId: dto.studentGroupId,
      },
    });

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      avatar: user.avatar,
    };
  }

  async refresh(dto: RefreshDto): Promise<TokenPair> {
    // Проверяем подпись токена
    let payload: { id: string };
    try {
      payload = jwt.verify(dto.refreshToken, jwtConfig.refreshSecret) as { id: string };
    } catch {
      throw ApiError.unauthorized('Недействительный refresh-токен');
    }

    // Проверяем, что токен есть в БД и не истёк
    const stored = await prisma.refreshToken.findUnique({
      where: { token: dto.refreshToken },
    });

    if (!stored || stored.expiresAt < new Date()) {
      if (stored) await prisma.refreshToken.delete({ where: { id: stored.id } });
      throw ApiError.unauthorized('Refresh-токен истёк или отозван');
    }

    const user = await prisma.user.findUnique({ where: { id: payload.id } });
    if (!user || !user.isActive) {
      throw ApiError.unauthorized('Пользователь не найден или деактивирован');
    }

    // Ротация refresh-токена: удаляем старый, создаём новый
    await prisma.refreshToken.delete({ where: { id: stored.id } });

    const tokens = generateTokenPair(user.id, user.email, user.role);
    await prisma.refreshToken.create({
      data: {
        token: tokens.refreshToken,
        userId: user.id,
        expiresAt: parseRefreshExpiry(),
      },
    });

    return tokens;
  }

  async logout(refreshToken: string): Promise<void> {
    // Инвалидируем конкретный refresh-токен
    await prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
  }

  async logoutAll(userId: string): Promise<void> {
    // Инвалидируем все сессии пользователя
    await prisma.refreshToken.deleteMany({ where: { userId } });
  }

  async getMe(userId: string): Promise<UserPayload & { middleName: string | null; phone: string | null }> {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw ApiError.notFound('Пользователь не найден');

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      middleName: user.middleName,
      phone: user.phone,
      avatar: user.avatar,
    };
  }
}

export const authService = new AuthService();
