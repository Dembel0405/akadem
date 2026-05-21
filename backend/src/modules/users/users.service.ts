import bcrypt from 'bcrypt';
import { Prisma } from '@prisma/client';
import prisma from '../../config/database';
import { ApiError } from '../../utils/ApiError';
import { parsePagination, buildPaginationMeta } from '../../utils/ApiResponse';
import type { UpdateUserDto, ChangePasswordDto, ListUsersQuery } from './users.schema';

// Поля, безопасные для возврата клиенту (без passwordHash)
const userSelect = {
  id: true,
  email: true,
  firstName: true,
  lastName: true,
  middleName: true,
  phone: true,
  avatar: true,
  role: true,
  isActive: true,
  createdAt: true,
  studentGroupId: true,
  studentGroup: { select: { id: true, name: true } },
} satisfies Prisma.UserSelect;

export class UsersService {
  async findAll(query: ListUsersQuery) {
    const { page, perPage, skip } = parsePagination(query);

    const where: Prisma.UserWhereInput = {};

    if (query.role) where.role = query.role;
    if (query.groupId) where.studentGroupId = query.groupId;
    if (query.isActive !== undefined) where.isActive = query.isActive === 'true';
    if (query.search) {
      where.OR = [
        { firstName: { contains: query.search, mode: 'insensitive' } },
        { lastName: { contains: query.search, mode: 'insensitive' } },
        { email: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({ where, select: userSelect, skip, take: perPage, orderBy: { lastName: 'asc' } }),
      prisma.user.count({ where }),
    ]);

    return { users, meta: buildPaginationMeta(total, page, perPage) };
  }

  async findById(id: string) {
    const user = await prisma.user.findUnique({ where: { id }, select: userSelect });
    if (!user) throw ApiError.notFound('Пользователь не найден');
    return user;
  }

  async update(id: string, dto: UpdateUserDto) {
    await this.findById(id); // гарантируем существование
    return prisma.user.update({ where: { id }, data: dto, select: userSelect });
  }

  async delete(id: string) {
    await this.findById(id);
    // Мягкое удаление — деактивируем, не удаляем из БД (сохраняем историю оценок/посещаемости)
    return prisma.user.update({ where: { id }, data: { isActive: false }, select: userSelect });
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw ApiError.notFound('Пользователь не найден');

    const isValid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!isValid) throw ApiError.badRequest('Текущий пароль неверен');

    const newHash = await bcrypt.hash(dto.newPassword, 10);
    await prisma.user.update({ where: { id: userId }, data: { passwordHash: newHash } });
  }

  async updateAvatar(userId: string, filename: string) {
    return prisma.user.update({
      where: { id: userId },
      data: { avatar: `/uploads/${filename}` },
      select: userSelect,
    });
  }
}

export const usersService = new UsersService();
