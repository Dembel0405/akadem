import { Request, Response } from 'express';
import { authService } from './auth.service';
import { ApiResponse } from '../../utils/ApiResponse';
import { ApiError } from '../../utils/ApiError';

/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: Авторизация и управление сессиями
 */
export class AuthController {
  /**
   * @swagger
   * /auth/login:
   *   post:
   *     summary: Вход в систему
   *     tags: [Auth]
   *     security: []
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required: [email, password]
   *             properties:
   *               email:
   *                 type: string
   *                 format: email
   *                 example: admin@college.kz
   *               password:
   *                 type: string
   *                 example: Admin123!
   *     responses:
   *       200:
   *         description: Успешный вход
   *       401:
   *         description: Неверные учётные данные
   */
  async login(req: Request, res: Response) {
    const result = await authService.login(req.body);
    return ApiResponse.success(res, result, 'Вход выполнен успешно');
  }

  /**
   * @swagger
   * /auth/register:
   *   post:
   *     summary: Регистрация нового пользователя (только для администраторов)
   *     tags: [Auth]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required: [email, password, firstName, lastName, role]
   *             properties:
   *               email:
   *                 type: string
   *               password:
   *                 type: string
   *               firstName:
   *                 type: string
   *               lastName:
   *                 type: string
   *               role:
   *                 type: string
   *                 enum: [ADMIN, TEACHER, STUDENT, CURATOR]
   *     responses:
   *       201:
   *         description: Пользователь создан
   *       409:
   *         description: Email уже занят
   */
  async register(req: Request, res: Response) {
    const user = await authService.register(req.body);
    return ApiResponse.created(res, user, 'Пользователь успешно создан');
  }

  /**
   * @swagger
   * /auth/refresh:
   *   post:
   *     summary: Обновление access-токена
   *     tags: [Auth]
   *     security: []
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required: [refreshToken]
   *             properties:
   *               refreshToken:
   *                 type: string
   *     responses:
   *       200:
   *         description: Новые токены
   *       401:
   *         description: Недействительный refresh-токен
   */
  async refresh(req: Request, res: Response) {
    const tokens = await authService.refresh(req.body);
    return ApiResponse.success(res, tokens, 'Токены обновлены');
  }

  /**
   * @swagger
   * /auth/logout:
   *   post:
   *     summary: Выход из системы
   *     tags: [Auth]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required: [refreshToken]
   *             properties:
   *               refreshToken:
   *                 type: string
   *     responses:
   *       200:
   *         description: Выход выполнен
   */
  async logout(req: Request, res: Response) {
    const { refreshToken } = req.body;
    if (!refreshToken) throw ApiError.badRequest('refreshToken обязателен');
    await authService.logout(refreshToken);
    return ApiResponse.success(res, null, 'Выход выполнен');
  }

  /**
   * @swagger
   * /auth/logout-all:
   *   post:
   *     summary: Выход со всех устройств
   *     tags: [Auth]
   *     responses:
   *       200:
   *         description: Все сессии завершены
   */
  async logoutAll(req: Request, res: Response) {
    await authService.logoutAll(req.user!.id);
    return ApiResponse.success(res, null, 'Все сессии завершены');
  }

  /**
   * @swagger
   * /auth/me:
   *   get:
   *     summary: Получить данные текущего пользователя
   *     tags: [Auth]
   *     responses:
   *       200:
   *         description: Данные пользователя
   */
  async getMe(req: Request, res: Response) {
    const user = await authService.getMe(req.user!.id);
    return ApiResponse.success(res, user);
  }
}

export const authController = new AuthController();
