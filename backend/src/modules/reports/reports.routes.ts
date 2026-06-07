import { Router } from 'express';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { ApiResponse } from '../../utils/ApiResponse';
import prisma from '../../config/database';

const router = Router();
router.use(authenticate);
router.use(authorize('ADMIN', 'TEACHER', 'CURATOR'));

/**
 * Отчёт по посещаемости группы.
 * В базовой версии возвращает JSON-данные; для PDF/Excel используется внешняя библиотека.
 */
router.get('/attendance/group/:groupId', async (req, res) => {
  const { groupId } = req.params;
  const { from, to } = req.query as { from?: string; to?: string };

  const group = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      students: {
        where: { isActive: true },
        orderBy: { lastName: 'asc' },
        select: { id: true, firstName: true, lastName: true, middleName: true },
      },
      specialty: { select: { name: true } },
    },
  });

  if (!group) {
    ApiResponse.error(res, 404, 'Группа не найдена', 'NOT_FOUND');
    return;
  }

  const where: any = { scheduleEntry: { groupId } };
  if (from || to) {
    where.date = {};
    if (from) where.date.gte = new Date(from);
    if (to) where.date.lte = new Date(to);
  }

  const attendanceRecords = await prisma.attendance.findMany({
    where,
    include: { scheduleEntry: { include: { subject: { select: { name: true } } } } },
    orderBy: { date: 'asc' },
  });

  // Формируем сводную таблицу: студент → статистика
  const studentStats = group.students.map((student) => {
    const studentRecords = attendanceRecords.filter((r) => r.studentId === student.id);
    const total = studentRecords.length;
    const present = studentRecords.filter((r) => r.status === 'PRESENT').length;
    const absent = studentRecords.filter((r) => r.status === 'ABSENT').length;
    const late = studentRecords.filter((r) => r.status === 'LATE').length;
    const excused = studentRecords.filter((r) => r.status === 'EXCUSED').length;
    const attendanceRate = total > 0 ? Math.round((present / total) * 100) : 100;

    return {
      student,
      stats: { total, present, absent, late, excused, attendanceRate },
    };
  });

  const totalPresent = attendanceRecords.filter((r) => r.status === 'PRESENT').length;
  const totalAbsent = attendanceRecords.filter((r) => r.status === 'ABSENT').length;
  const totalLate = attendanceRecords.filter((r) => r.status === 'LATE').length;
  const totalExcused = attendanceRecords.filter((r) => r.status === 'EXCUSED').length;

  ApiResponse.success(res, {
    group: { id: group.id, name: group.name, specialty: group.specialty.name },
    period: { from: from ?? null, to: to ?? null },
    studentStats,
    PRESENT: totalPresent,
    ABSENT: totalAbsent,
    LATE: totalLate,
    EXCUSED: totalExcused,
  });
});

/**
 * Отчёт по успеваемости группы.
 */
router.get('/grades/group/:groupId', async (req, res) => {
  const { groupId } = req.params;
  const { subjectId } = req.query as { subjectId?: string };

  const group = await prisma.group.findUnique({
    where: { id: groupId },
    include: {
      students: {
        where: { isActive: true },
        orderBy: { lastName: 'asc' },
        select: { id: true, firstName: true, lastName: true },
      },
    },
  });

  if (!group) {
    ApiResponse.error(res, 404, 'Группа не найдена', 'NOT_FOUND');
    return;
  }

  const studentIds = group.students.map((s) => s.id);
  const where: any = { studentId: { in: studentIds } };
  if (subjectId) where.subjectId = subjectId;

  const grades = await prisma.grade.findMany({
    where,
    include: { subject: { select: { id: true, name: true } } },
  });

  const studentStats = group.students.map((student) => {
    const studentGrades = grades.filter((g) => g.studentId === student.id);
    const average = studentGrades.length
      ? Math.round((studentGrades.reduce((sum, g) => sum + g.value, 0) / studentGrades.length) * 100) / 100
      : null;

    // Группируем по дисциплинам
    const bySubject: Record<string, { subjectName: string; average: number; count: number }> = {};
    studentGrades.forEach((g) => {
      if (!bySubject[g.subjectId]) {
        bySubject[g.subjectId] = { subjectName: g.subject.name, average: 0, count: 0 };
      }
      bySubject[g.subjectId].count += 1;
      bySubject[g.subjectId].average += g.value;
    });

    Object.values(bySubject).forEach((s) => {
      s.average = Math.round((s.average / s.count) * 100) / 100;
    });

    return { student, average, bySubject: Object.values(bySubject) };
  });

  ApiResponse.success(res, {
    group: { id: group.id, name: group.name },
    studentStats,
  });
});

export default router;
