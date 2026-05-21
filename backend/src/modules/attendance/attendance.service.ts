import { AttendanceStatus, Prisma } from '@prisma/client';
import prisma from '../../config/database';
import { ApiError } from '../../utils/ApiError';
import { z } from 'zod';

export const markAttendanceSchema = z.object({
  scheduleEntryId: z.string().uuid(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Формат даты: YYYY-MM-DD'),
  records: z.array(
    z.object({
      studentId: z.string().uuid(),
      status: z.nativeEnum(AttendanceStatus),
      note: z.string().optional(),
    }),
  ).min(1),
});

export class AttendanceService {
  // Отметить посещаемость для всей группы на конкретном занятии
  async markAttendance(teacherId: string, dto: z.infer<typeof markAttendanceSchema>) {
    const entry = await prisma.scheduleEntry.findUnique({ where: { id: dto.scheduleEntryId } });
    if (!entry) throw ApiError.notFound('Занятие не найдено');
    if (entry.teacherId !== teacherId) throw ApiError.forbidden('Вы не ведёте это занятие');

    const date = new Date(dto.date);

    // Upsert каждой записи: создаём или обновляем
    const operations = dto.records.map((r) =>
      prisma.attendance.upsert({
        where: {
          studentId_scheduleEntryId_date: {
            studentId: r.studentId,
            scheduleEntryId: dto.scheduleEntryId,
            date,
          },
        },
        update: { status: r.status, note: r.note },
        create: {
          studentId: r.studentId,
          scheduleEntryId: dto.scheduleEntryId,
          date,
          status: r.status,
          note: r.note,
        },
      }),
    );

    return prisma.$transaction(operations);
  }

  // Посещаемость студента по дисциплинам
  async getStudentAttendance(studentId: string, query: { subjectId?: string; from?: string; to?: string }) {
    const where: Prisma.AttendanceWhereInput = { studentId };

    if (query.from || query.to) {
      where.date = {};
      if (query.from) where.date.gte = new Date(query.from);
      if (query.to) where.date.lte = new Date(query.to);
    }

    if (query.subjectId) {
      where.scheduleEntry = { subjectId: query.subjectId };
    }

    const records = await prisma.attendance.findMany({
      where,
      orderBy: { date: 'desc' },
      include: {
        scheduleEntry: {
          include: { subject: { select: { id: true, name: true } } },
        },
      },
    });

    // Статистика по статусам
    const stats = records.reduce(
      (acc, r) => {
        acc[r.status] = (acc[r.status] ?? 0) + 1;
        acc.total += 1;
        return acc;
      },
      { total: 0, PRESENT: 0, ABSENT: 0, LATE: 0, EXCUSED: 0 } as Record<string, number>,
    );

    return { records, stats };
  }

  // Посещаемость группы на конкретном занятии за дату
  async getGroupAttendance(scheduleEntryId: string, date: string) {
    const entry = await prisma.scheduleEntry.findUnique({
      where: { id: scheduleEntryId },
      include: { group: { include: { students: { where: { isActive: true }, orderBy: { lastName: 'asc' } } } } },
    });

    if (!entry) throw ApiError.notFound('Занятие не найдено');

    const existing = await prisma.attendance.findMany({
      where: { scheduleEntryId, date: new Date(date) },
    });

    const attendanceMap = new Map(existing.map((a) => [a.studentId, a]));

    // Объединяем список студентов с записями посещаемости
    const result = entry.group.students.map((student) => ({
      student: { id: student.id, firstName: student.firstName, lastName: student.lastName },
      attendance: attendanceMap.get(student.id) ?? null,
    }));

    return result;
  }

  // Статистика посещаемости по группе
  async getGroupStats(groupId: string, query: { from?: string; to?: string }) {
    const where: Prisma.AttendanceWhereInput = {
      scheduleEntry: { groupId },
    };

    if (query.from || query.to) {
      where.date = {};
      if (query.from) (where.date as any).gte = new Date(query.from);
      if (query.to) (where.date as any).lte = new Date(query.to);
    }

    const records = await prisma.attendance.groupBy({
      by: ['status'],
      where,
      _count: true,
    });

    return records.reduce(
      (acc, r) => ({ ...acc, [r.status]: r._count }),
      {} as Record<string, number>,
    );
  }
}

export const attendanceService = new AttendanceService();
