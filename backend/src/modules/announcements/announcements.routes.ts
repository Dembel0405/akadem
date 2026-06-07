import { Router } from 'express';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { ApiResponse } from '../../utils/ApiResponse';
import { parsePagination, buildPaginationMeta } from '../../utils/ApiResponse';
import prisma from '../../config/database';
import { ApiError } from '../../utils/ApiError';
import { z } from 'zod';
import { AnnouncementTarget } from '@prisma/client';

const createSchema = z.object({
  title: z.string().min(3).max(200),
  content: z.string().min(10),
  isPinned: z.boolean().default(false),
  targetRoles: z.array(z.nativeEnum(AnnouncementTarget)).default(['ALL']),
});

const router = Router();
router.use(authenticate);

router.get('/', async (req, res) => {
  const { page, perPage, skip } = parsePagination(req.query as any);
  const role = req.user!.role;

  // Роль пользователя → цель объявления (множественное число в enum)
  const roleToTarget: Partial<Record<string, AnnouncementTarget>> = {
    STUDENT: AnnouncementTarget.STUDENTS,
    TEACHER: AnnouncementTarget.TEACHERS,
    CURATOR: AnnouncementTarget.CURATORS,
  };

  // Администратор видит все объявления (для управления).
  // Остальные видят адресованные им + общие (ALL).
  const where = role === 'ADMIN'
    ? {}
    : {
        OR: [
          { targetRoles: { has: AnnouncementTarget.ALL } },
          ...(roleToTarget[role] ? [{ targetRoles: { has: roleToTarget[role]! } }] : []),
        ],
      };

  const [items, total] = await Promise.all([
    prisma.announcement.findMany({
      where,
      orderBy: [{ isPinned: 'desc' }, { createdAt: 'desc' }],
      skip,
      take: perPage,
      include: { author: { select: { id: true, firstName: true, lastName: true } } },
    }),
    prisma.announcement.count({ where }),
  ]);

  ApiResponse.paginated(res, items, buildPaginationMeta(total, page, perPage));
});

router.get('/:id', async (req, res) => {
  const item = await prisma.announcement.findUnique({
    where: { id: req.params.id },
    include: { author: { select: { id: true, firstName: true, lastName: true } } },
  });
  if (!item) throw ApiError.notFound('Объявление не найдено');
  ApiResponse.success(res, item);
});

router.post('/', authorize('ADMIN', 'TEACHER'), validateBody(createSchema), async (req, res) => {
  const item = await prisma.announcement.create({
    data: { ...req.body, authorId: req.user!.id },
    include: { author: { select: { id: true, firstName: true, lastName: true } } },
  });
  ApiResponse.created(res, item, 'Объявление создано');
});

router.patch('/:id', authorize('ADMIN', 'TEACHER'), validateBody(createSchema.partial()), async (req, res) => {
  const existing = await prisma.announcement.findUnique({ where: { id: req.params.id } });
  if (!existing) throw ApiError.notFound('Объявление не найдено');
  if (existing.authorId !== req.user!.id && req.user!.role !== 'ADMIN') {
    throw ApiError.forbidden('Вы можете редактировать только свои объявления');
  }

  const item = await prisma.announcement.update({ where: { id: req.params.id }, data: req.body });
  ApiResponse.success(res, item, 'Объявление обновлено');
});

router.delete('/:id', authorize('ADMIN', 'TEACHER'), async (req, res) => {
  const existing = await prisma.announcement.findUnique({ where: { id: req.params.id } });
  if (!existing) throw ApiError.notFound('Объявление не найдено');
  if (existing.authorId !== req.user!.id && req.user!.role !== 'ADMIN') {
    throw ApiError.forbidden('Вы можете удалять только свои объявления');
  }

  await prisma.announcement.delete({ where: { id: req.params.id } });
  ApiResponse.noContent(res);
});

export default router;
