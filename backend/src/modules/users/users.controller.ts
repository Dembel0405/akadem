import { Request, Response } from 'express';
import { usersService } from './users.service';
import { ApiResponse } from '../../utils/ApiResponse';
import { ApiError } from '../../utils/ApiError';

export class UsersController {
  async getAll(req: Request, res: Response) {
    const { users, meta } = await usersService.findAll(req.query as any);
    return ApiResponse.paginated(res, users, meta);
  }

  async getById(req: Request, res: Response) {
    const user = await usersService.findById(req.params.id);
    return ApiResponse.success(res, user);
  }

  async update(req: Request, res: Response) {
    const user = await usersService.update(req.params.id, req.body);
    return ApiResponse.success(res, user, 'Данные пользователя обновлены');
  }

  async delete(req: Request, res: Response) {
    await usersService.delete(req.params.id);
    return ApiResponse.success(res, null, 'Пользователь деактивирован');
  }

  async changePassword(req: Request, res: Response) {
    await usersService.changePassword(req.user!.id, req.body);
    return ApiResponse.success(res, null, 'Пароль успешно изменён');
  }

  async uploadAvatar(req: Request, res: Response) {
    if (!req.file) throw ApiError.badRequest('Файл не загружен');
    const user = await usersService.updateAvatar(req.user!.id, req.file.filename);
    return ApiResponse.success(res, user, 'Аватар обновлён');
  }

  // Пользователь может обновить только свой профиль (без смены роли/группы)
  async updateMe(req: Request, res: Response) {
    const { firstName, lastName, middleName, phone } = req.body;
    const user = await usersService.update(req.user!.id, { firstName, lastName, middleName, phone });
    return ApiResponse.success(res, user, 'Профиль обновлён');
  }
}

export const usersController = new UsersController();
