import { DayOfWeek, WeekType, Prisma } from '@prisma/client';
import prisma from '../../config/database';
import { ApiError } from '../../utils/ApiError';
import { z } from 'zod';

export const createEntrySchema = z.object({
  groupId: z.string().uuid(),
  subjectId: z.string().uuid(),
  teacherId: z.string().uuid(),
  dayOfWeek: z.nativeEnum(DayOfWeek),
  startTime: z.string().regex(/^\d{2}:\d{2}$/, 'Формат: HH:MM'),
  endTime: z.string().regex(/^\d{2}:\d{2}$/, 'Формат: HH:MM'),
  room: z.string().optional(),
  weekType: z.nativeEnum(WeekType).default('ALL'),
});

const entryInclude = {
  group: { select: { id: true, name: true } },
  subject: { select: { id: true, name: true, code: true } },
  teacher: { select: { id: true, firstName: true, lastName: true } },
} satisfies Prisma.ScheduleEntryInclude;

export class ScheduleService {
  async getGroupSchedule(groupId: string) {
    return prisma.scheduleEntry.findMany({
      where: { groupId, isActive: true },
      orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
      include: entryInclude,
    });
  }

  async getTeacherSchedule(teacherId: string) {
    return prisma.scheduleEntry.findMany({
      where: { teacherId, isActive: true },
      orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
      include: entryInclude,
    });
  }

  async getMySchedule(userId: string, role: string) {
    if (role === 'TEACHER') {
      return this.getTeacherSchedule(userId);
    }

    if (role === 'STUDENT') {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { studentGroupId: true },
      });
      if (!user?.studentGroupId) return [];
      return this.getGroupSchedule(user.studentGroupId);
    }

    return [];
  }

  async create(dto: z.infer<typeof createEntrySchema>) {
    // Проверка конфликтов: одна группа не может иметь 2 урока в одно время
    const conflict = await prisma.scheduleEntry.findFirst({
      where: {
        groupId: dto.groupId,
        dayOfWeek: dto.dayOfWeek,
        startTime: dto.startTime,
        isActive: true,
        weekType: dto.weekType === 'ALL' ? undefined : dto.weekType,
      },
    });

    if (conflict) {
      throw ApiError.conflict('В это время у группы уже есть занятие');
    }

    return prisma.scheduleEntry.create({ data: dto, include: entryInclude });
  }

  async update(id: string, dto: Partial<z.infer<typeof createEntrySchema>>) {
    const entry = await prisma.scheduleEntry.findUnique({ where: { id } });
    if (!entry) throw ApiError.notFound('Запись расписания не найдена');

    return prisma.scheduleEntry.update({ where: { id }, data: dto, include: entryInclude });
  }

  async delete(id: string) {
    const entry = await prisma.scheduleEntry.findUnique({ where: { id } });
    if (!entry) throw ApiError.notFound('Запись расписания не найдена');
    return prisma.scheduleEntry.update({ where: { id }, data: { isActive: false } });
  }
}

export const scheduleService = new ScheduleService();
