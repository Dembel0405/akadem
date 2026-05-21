import { Router } from 'express';
import { usersController } from './users.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { validateBody, validateQuery } from '../../middleware/validate.middleware';
import { uploadAvatar } from '../../middleware/upload.middleware';
import { updateUserSchema, changePasswordSchema, listUsersQuerySchema } from './users.schema';

const router = Router();

// Все маршруты требуют авторизации
router.use(authenticate);

// Текущий пользователь
router.get('/me', usersController.updateMe.bind(usersController)); // handled in auth/me
router.patch('/me', validateBody(updateUserSchema), usersController.updateMe.bind(usersController));
router.post('/me/password', validateBody(changePasswordSchema), usersController.changePassword.bind(usersController));
router.post('/me/avatar', uploadAvatar, usersController.uploadAvatar.bind(usersController));

// Управление пользователями — только для администраторов
router.get('/', authorize('ADMIN'), validateQuery(listUsersQuerySchema), usersController.getAll.bind(usersController));
router.get('/:id', authorize('ADMIN', 'CURATOR'), usersController.getById.bind(usersController));
router.patch('/:id', authorize('ADMIN'), validateBody(updateUserSchema), usersController.update.bind(usersController));
router.delete('/:id', authorize('ADMIN'), usersController.delete.bind(usersController));

export default router;
