import { Router } from 'express';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { ApiResponse } from '../../utils/ApiResponse';
import prisma from '../../config/database';
import { ApiError } from '../../utils/ApiError';
import { z } from 'zod';

const createSchema = z.object({
  name: z.string().min(3).max(200),
  code: z.string().min(2).max(20),
  description: z.string().optional(),
});

const router = Router();
router.use(authenticate);

router.get('/', async (_req, res) => {
  const specialties = await prisma.specialty.findMany({
    where: { isActive: true },
    orderBy: { name: 'asc' },
    include: { _count: { select: { groups: true } } },
  });
  ApiResponse.success(res, specialties);
});

router.get('/:id', async (req, res) => {
  const specialty = await prisma.specialty.findUnique({
    where: { id: req.params.id },
    include: { groups: { where: { isActive: true }, select: { id: true, name: true, year: true } } },
  });
  if (!specialty) throw ApiError.notFound('Специальность не найдена');
  ApiResponse.success(res, specialty);
});

router.post('/', authorize('ADMIN'), validateBody(createSchema), async (req, res) => {
  const specialty = await prisma.specialty.create({ data: req.body });
  ApiResponse.created(res, specialty, 'Специальность создана');
});

router.patch('/:id', authorize('ADMIN'), validateBody(createSchema.partial()), async (req, res) => {
  const specialty = await prisma.specialty.update({ where: { id: req.params.id }, data: req.body });
  ApiResponse.success(res, specialty, 'Специальность обновлена');
});

router.delete('/:id', authorize('ADMIN'), async (req, res) => {
  await prisma.specialty.update({ where: { id: req.params.id }, data: { isActive: false } });
  ApiResponse.success(res, null, 'Специальность деактивирована');
});

export default router;
