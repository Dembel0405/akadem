import { Role } from '@prisma/client';

// Расширяем стандартный Request Express, добавляя поле user после JWT-верификации
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        role: Role;
      };
    }
  }
}

export {};
