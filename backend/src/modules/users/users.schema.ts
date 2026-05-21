import { z } from 'zod';

export const updateUserSchema = z.object({
  firstName: z.string().min(2).max(50).optional(),
  lastName: z.string().min(2).max(50).optional(),
  middleName: z.string().max(50).optional().nullable(),
  phone: z.string().optional().nullable(),
  studentGroupId: z.string().uuid().optional().nullable(),
  isActive: z.boolean().optional(),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Текущий пароль обязателен'),
  newPassword: z
    .string()
    .min(8, 'Новый пароль должен содержать минимум 8 символов')
    .regex(/[A-Z]/, 'Должна быть хотя бы одна заглавная буква')
    .regex(/[0-9]/, 'Должна быть хотя бы одна цифра'),
});

export const listUsersQuerySchema = z.object({
  page: z.string().optional(),
  perPage: z.string().optional(),
  role: z.enum(['ADMIN', 'TEACHER', 'STUDENT', 'CURATOR']).optional(),
  groupId: z.string().uuid().optional(),
  search: z.string().optional(),
  isActive: z.enum(['true', 'false']).optional(),
});

export type UpdateUserDto = z.infer<typeof updateUserSchema>;
export type ChangePasswordDto = z.infer<typeof changePasswordSchema>;
export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;
