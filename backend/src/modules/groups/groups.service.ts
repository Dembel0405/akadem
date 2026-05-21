import { Prisma } from '@prisma/client';
import prisma from '../../config/database';
import { ApiError } from '../../utils/ApiError';
import { parsePagination, buildPaginationMeta } from '../../utils/ApiResponse';
import { z } from 'zod';

export const createGroupSchema = z.object({
  name: z.string().min(2).max(20),
  year: z.number().int().min(2000).max(2100),
  specialtyId: z.string().uuid(),
  curatorId: z.string().uuid().optional(),
});

export const updateGroupSchema = createGroupSchema.partial();

export class GroupsService {
  async findAll(query: { page?: string; perPage?: string; search?: string; specialtyId?: string }) {
    const { page, perPage, skip } = parsePagination(query);

    const where: Prisma.GroupWhereInput = { isActive: true };
    if (query.specialtyId) where.specialtyId = query.specialtyId;
    if (query.search) where.name = { contains: query.search, mode: 'insensitive' };

    const [groups, total] = await Promise.all([
      prisma.group.findMany({
        where,
        skip,
        take: perPage,
        orderBy: { name: 'asc' },
        include: {
          specialty: { select: { id: true, name: true, code: true } },
          curator: { select: { id: true, firstName: true, lastName: true } },
          _count: { select: { students: true } },
        },
      }),
      prisma.group.count({ where }),
    ]);

    return { groups, meta: buildPaginationMeta(total, page, perPage) };
  }

  async findById(id: string) {
    const group = await prisma.group.findUnique({
      where: { id },
      include: {
        specialty: true,
        curator: { select: { id: true, firstName: true, lastName: true, email: true, phone: true } },
        students: {
          where: { isActive: true },
          select: { id: true, firstName: true, lastName: true, middleName: true, email: true, avatar: true },
          orderBy: { lastName: 'asc' },
        },
      },
    });

    if (!group) throw ApiError.notFound('Группа не найдена');
    return group;
  }

  async create(dto: z.infer<typeof createGroupSchema>) {
    const exists = await prisma.group.findUnique({ where: { name: dto.name } });
    if (exists) throw ApiError.conflict(`Группа "${dto.name}" уже существует`);

    return prisma.group.create({
      data: dto,
      include: { specialty: { select: { id: true, name: true } } },
    });
  }

  async update(id: string, dto: z.infer<typeof updateGroupSchema>) {
    await this.findById(id);
    return prisma.group.update({
      where: { id },
      data: dto,
      include: { specialty: { select: { id: true, name: true } } },
    });
  }

  async delete(id: string) {
    await this.findById(id);
    return prisma.group.update({ where: { id }, data: { isActive: false } });
  }
}

export const groupsService = new GroupsService();
