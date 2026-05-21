import { Router } from 'express';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { ApiResponse } from '../../utils/ApiResponse';
import prisma from '../../config/database';
import { ApiError } from '../../utils/ApiError';
import { z } from 'zod';

const createSchema = z.object({
  name: z.string().min(3).max(200),
  code: z.string().min(2).max(30),
  description: z.string().optional(),
  hoursTotal: z.number().int().min(1),
  credits: z.number().int().min(0).optional(),
});

const router = Router();
router.use(authenticate);

router.get('/', async (_req, res) => {
  const subjects = await prisma.subject.findMany({
    where: { isActive: true },
    orderBy: { name: 'asc' },
  });
  ApiResponse.success(res, subjects);
});

router.get('/:id', async (req, res) => {
  const subject = await prisma.subject.findUnique({ where: { id: req.params.id } });
  if (!subject) throw ApiError.notFound('Дисциплина не найдена');
  ApiResponse.success(res, subject);
});

router.post('/', authorize('ADMIN'), validateBody(createSchema), async (req, res) => {
  const subject = await prisma.subject.create({ data: req.body });
  ApiResponse.created(res, subject, 'Дисциплина создана');
});

router.patch('/:id', authorize('ADMIN'), validateBody(createSchema.partial()), async (req, res) => {
  const subject = await prisma.subject.update({ where: { id: req.params.id }, data: req.body });
  ApiResponse.success(res, subject, 'Дисциплина обновлена');
});

router.delete('/:id', authorize('ADMIN'), async (req, res) => {
  await prisma.subject.update({ where: { id: req.params.id }, data: { isActive: false } });
  ApiResponse.success(res, null, 'Дисциплина деактивирована');
});

export default router;
