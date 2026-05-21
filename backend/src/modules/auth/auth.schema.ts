import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email('Неверный формат email'),
  password: z.string().min(1, 'Пароль обязателен'),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh-токен обязателен'),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email('Неверный формат email'),
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1),
  password: z
    .string()
    .min(8, 'Пароль должен содержать минимум 8 символов')
    .regex(/[A-Z]/, 'Пароль должен содержать хотя бы одну заглавную букву')
    .regex(/[0-9]/, 'Пароль должен содержать хотя бы одну цифру'),
});

export const registerSchema = z.object({
  email: z.string().email('Неверный формат email'),
  password: z
    .string()
    .min(8, 'Пароль должен содержать минимум 8 символов')
    .regex(/[A-Z]/, 'Пароль должен содержать хотя бы одну заглавную букву')
    .regex(/[0-9]/, 'Пароль должен содержать хотя бы одну цифру'),
  firstName: z.string().min(2, 'Имя обязательно').max(50),
  lastName: z.string().min(2, 'Фамилия обязательна').max(50),
  middleName: z.string().max(50).optional(),
  role: z.enum(['ADMIN', 'TEACHER', 'STUDENT', 'CURATOR']),
  phone: z.string().optional(),
  studentGroupId: z.string().uuid().optional(),
});

export type LoginDto = z.infer<typeof loginSchema>;
export type RefreshDto = z.infer<typeof refreshSchema>;
export type ForgotPasswordDto = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordDto = z.infer<typeof resetPasswordSchema>;
export type RegisterDto = z.infer<typeof registerSchema>;
