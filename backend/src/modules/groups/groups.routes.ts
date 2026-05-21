import { Router } from 'express';
import { groupsService, createGroupSchema, updateGroupSchema } from './groups.service';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { ApiResponse } from '../../utils/ApiResponse';

const router = Router();
router.use(authenticate);

router.get('/', async (req, res) => {
  const result = await groupsService.findAll(req.query as any);
  ApiResponse.paginated(res, result.groups, result.meta);
});

router.get('/:id', async (req, res) => {
  const group = await groupsService.findById(req.params.id);
  ApiResponse.success(res, group);
});

router.post('/', authorize('ADMIN'), validateBody(createGroupSchema), async (req, res) => {
  const group = await groupsService.create(req.body);
  ApiResponse.created(res, group, 'Группа создана');
});

router.patch('/:id', authorize('ADMIN'), validateBody(updateGroupSchema), async (req, res) => {
  const group = await groupsService.update(req.params.id, req.body);
  ApiResponse.success(res, group, 'Группа обновлена');
});

router.delete('/:id', authorize('ADMIN'), async (req, res) => {
  await groupsService.delete(req.params.id);
  ApiResponse.success(res, null, 'Группа деактивирована');
});

export default router;
