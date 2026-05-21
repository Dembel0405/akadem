import { Router } from 'express';
import { authenticate } from '../../middleware/auth.middleware';
import { ApiResponse } from '../../utils/ApiResponse';
import prisma from '../../config/database';

const router = Router();
router.use(authenticate);

/**
 * Дашборд возвращает разные данные в зависимости от роли пользователя.
 * Один эндпоинт — меньше клиентского кода.
 */
router.get('/', async (req, res) => {
  const { id, role } = req.user!;

  if (role === 'ADMIN') {
    const [totalStudents, totalTeachers, totalGroups, recentAnnouncements] = await Promise.all([
      prisma.user.count({ where: { role: 'STUDENT', isActive: true } }),
      prisma.user.count({ where: { role: 'TEACHER', isActive: true } }),
      prisma.group.count({ where: { isActive: true } }),
      prisma.announcement.findMany({
        take: 5,
        orderBy: { createdAt: 'desc' },
        include: { author: { select: { firstName: true, lastName: true } } },
      }),
    ]);

    // Посещаемость за текущую неделю
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    const attendanceStats = await prisma.attendance.groupBy({
      by: ['status'],
      where: { date: { gte: weekAgo } },
      _count: true,
    });

    return ApiResponse.success(res, {
      role: 'ADMIN',
      stats: { totalStudents, totalTeachers, totalGroups },
      attendanceStats: attendanceStats.reduce<Record<string, number>>(
        (acc, s) => ({ ...acc, [s.status]: s._count }),
        {},
      ),
      recentAnnouncements,
    });
  }

  if (role === 'STUDENT') {
    const user = await prisma.user.findUnique({
      where: { id },
      include: { studentGroup: { include: { specialty: true } } },
    });

    const grades = await prisma.grade.findMany({
      where: { studentId: id },
      include: { subject: { select: { id: true, name: true } } },
      orderBy: { date: 'desc' },
      take: 10,
    });

    const attendanceStats = await prisma.attendance.groupBy({
      by: ['status'],
      where: { studentId: id },
      _count: true,
    });

    const announcements = await prisma.announcement.findMany({
      where: { OR: [{ targetRoles: { has: 'ALL' } }, { targetRoles: { has: 'STUDENTS' } }] },
      take: 3,
      orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
    });

    return ApiResponse.success(res, {
      role: 'STUDENT',
      group: user?.studentGroup ?? null,
      recentGrades: grades,
      attendanceStats: attendanceStats.reduce<Record<string, number>>(
        (acc, s) => ({ ...acc, [s.status]: s._count }),
        {},
      ),
      announcements,
    });
  }

  if (role === 'TEACHER') {
    const scheduleEntries = await prisma.scheduleEntry.findMany({
      where: { teacherId: id, isActive: true },
      include: {
        group: { select: { id: true, name: true } },
        subject: { select: { id: true, name: true } },
      },
      distinct: ['groupId', 'subjectId'],
    });

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Количество занятий сегодня
    const dayOfWeek = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'][today.getDay()];
    const todayClasses = await prisma.scheduleEntry.count({
      where: { teacherId: id, isActive: true, dayOfWeek: dayOfWeek as any },
    });

    return ApiResponse.success(res, {
      role: 'TEACHER',
      stats: {
        groupsCount: new Set(scheduleEntries.map((e) => e.groupId)).size,
        subjectsCount: new Set(scheduleEntries.map((e) => e.subjectId)).size,
        todayClasses,
      },
      groupsAndSubjects: scheduleEntries,
    });
  }

  if (role === 'CURATOR') {
    const curator = await prisma.user.findUnique({
      where: { id },
      include: { curatedGroup: { include: { students: { where: { isActive: true } } } } },
    });

    if (!curator?.curatedGroup) {
      return ApiResponse.success(res, { role: 'CURATOR', group: null });
    }

    const group = curator.curatedGroup;
    const studentIds = group.students.map((s) => s.id);

    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);

    const attendanceStats = await prisma.attendance.groupBy({
      by: ['status'],
      where: { studentId: { in: studentIds }, date: { gte: weekAgo } },
      _count: true,
    });

    return ApiResponse.success(res, {
      role: 'CURATOR',
      group: { id: group.id, name: group.name, studentsCount: group.students.length },
      attendanceStats: attendanceStats.reduce<Record<string, number>>(
        (acc, s) => ({ ...acc, [s.status]: s._count }),
        {},
      ),
    });
  }

  return ApiResponse.success(res, { role });
});

export default router;
