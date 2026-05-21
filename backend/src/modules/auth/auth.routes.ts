import { Router } from 'express';
import { authController } from './auth.controller';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import {
  loginSchema,
  registerSchema,
  refreshSchema,
} from './auth.schema';

const router = Router();

// Публичные маршруты
router.post('/login', validateBody(loginSchema), authController.login.bind(authController));
router.post('/refresh', validateBody(refreshSchema), authController.refresh.bind(authController));

// Защищённые маршруты
router.post('/logout', authenticate, authController.logout.bind(authController));
router.post('/logout-all', authenticate, authController.logoutAll.bind(authController));
router.get('/me', authenticate, authController.getMe.bind(authController));

// Только администратор может создавать пользователей
router.post(
  '/register',
  authenticate,
  authorize('ADMIN'),
  validateBody(registerSchema),
  authController.register.bind(authController),
);

export default router;
