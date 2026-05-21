import { GradeType, Prisma } from '@prisma/client';
import prisma from '../../config/database';
import { ApiError } from '../../utils/ApiError';
import { z } from 'zod';

export const createGradeSchema = z.object({
  studentId: z.string().uuid(),
  subjectId: z.string().uuid(),
  value: z.number().int().min(2).max(5),
  type: z.nativeEnum(GradeType).default('CURRENT'),
  date: z.string().optional(),
  comment: z.string().max(500).optional(),
});

const gradeInclude = {
  student: { select: { id: true, firstName: true, lastName: true } },
  subject: { select: { id: true, name: true, code: true } },
  teacher: { select: { id: true, firstName: true, lastName: true } },
} satisfies Prisma.GradeInclude;

export class GradesService {
  // Журнал оценок студента по всем дисциплинам
  async getStudentGrades(studentId: string, subjectId?: string) {
    const where: Prisma.GradeWhereInput = { studentId };
    if (subjectId) where.subjectId = subjectId;

    const grades = await prisma.grade.findMany({
      where,
      orderBy: { date: 'desc' },
      include: gradeInclude,
    });

    // Группируем по дисциплинам
    const bySubject = grades.reduce<Record<string, { subject: any; grades: any[]; average: number }>>((acc, g) => {
      const key = g.subjectId;
      if (!acc[key]) {
        acc[key] = { subject: g.subject, grades: [], average: 0 };
      }
      acc[key].grades.push(g);
      return acc;
    }, {});

    // Вычисляем средний балл по каждой дисциплине
    Object.values(bySubject).forEach((s) => {
      s.average = s.grades.reduce((sum, g) => sum + g.value, 0) / s.grades.length;
      s.average = Math.round(s.average * 100) / 100;
    });

    const totalAverage = grades.length > 0
      ? Math.round((grades.reduce((sum, g) => sum + g.value, 0) / grades.length) * 100) / 100
      : 0;

    return { bySubject: Object.values(bySubject), totalAverage };
  }

  // Журнал оценок для преподавателя по группе и дисциплине
  async getGroupGrades(teacherId: string, groupId: string, subjectId: string) {
    const students = await prisma.user.findMany({
      where: { studentGroupId: groupId, isActive: true },
      select: { id: true, firstName: true, lastName: true, middleName: true },
      orderBy: { lastName: 'asc' },
    });

    const grades = await prisma.grade.findMany({
      where: { subjectId, teacherId, student: { studentGroupId: groupId } },
      orderBy: { date: 'desc' },
    });

    const gradesByStudent = grades.reduce<Record<string, any[]>>((acc, g) => {
      if (!acc[g.studentId]) acc[g.studentId] = [];
      acc[g.studentId].push(g);
      return acc;
    }, {});

    return students.map((s) => ({
      student: s,
      grades: gradesByStudent[s.id] ?? [],
      average: gradesByStudent[s.id]?.length
        ? Math.round((gradesByStudent[s.id].reduce((sum, g) => sum + g.value, 0) / gradesByStudent[s.id].length) * 100) / 100
        : null,
    }));
  }

  async create(teacherId: string, dto: z.infer<typeof createGradeSchema>) {
    return prisma.grade.create({
      data: {
        ...dto,
        teacherId,
        date: dto.date ? new Date(dto.date) : new Date(),
      },
      include: gradeInclude,
    });
  }

  async update(id: string, teacherId: string, dto: Partial<z.infer<typeof createGradeSchema>>) {
    const grade = await prisma.grade.findUnique({ where: { id } });
    if (!grade) throw ApiError.notFound('Оценка не найдена');
    if (grade.teacherId !== teacherId) throw ApiError.forbidden('Вы можете изменять только свои оценки');

    return prisma.grade.update({ where: { id }, data: dto, include: gradeInclude });
  }

  async delete(id: string, teacherId: string) {
    const grade = await prisma.grade.findUnique({ where: { id } });
    if (!grade) throw ApiError.notFound('Оценка не найдена');
    if (grade.teacherId !== teacherId) throw ApiError.forbidden('Вы можете удалять только свои оценки');

    await prisma.grade.delete({ where: { id } });
  }
}

export const gradesService = new GradesService();
