import { Router } from 'express';
import { scheduleService, createEntrySchema } from './schedule.service';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { ApiResponse } from '../../utils/ApiResponse';

const router = Router();
router.use(authenticate);

// Моё расписание (для студента — по группе, для преподавателя — по преподавателю)
router.get('/my', async (req, res) => {
  const entries = await scheduleService.getMySchedule(req.user!.id, req.user!.role);
  ApiResponse.success(res, entries);
});

router.get('/group/:groupId', async (req, res) => {
  const entries = await scheduleService.getGroupSchedule(req.params.groupId);
  ApiResponse.success(res, entries);
});

router.get('/teacher/:teacherId', async (req, res) => {
  const entries = await scheduleService.getTeacherSchedule(req.params.teacherId);
  ApiResponse.success(res, entries);
});

router.post('/', authorize('ADMIN'), validateBody(createEntrySchema), async (req, res) => {
  const entry = await scheduleService.create(req.body);
  ApiResponse.created(res, entry, 'Занятие добавлено в расписание');
});

router.patch('/:id', authorize('ADMIN'), validateBody(createEntrySchema.partial()), async (req, res) => {
  const entry = await scheduleService.update(req.params.id, req.body);
  ApiResponse.success(res, entry, 'Расписание обновлено');
});

router.delete('/:id', authorize('ADMIN'), async (req, res) => {
  await scheduleService.delete(req.params.id);
  ApiResponse.success(res, null, 'Занятие удалено из расписания');
});

export default router;
