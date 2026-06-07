import 'express-async-errors';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import swaggerUi from 'swagger-ui-express';
import path from 'path';

import { requestLogger } from './middleware/logger.middleware';
import { errorHandler } from './middleware/error.middleware';
import { swaggerSpec } from './config/swagger';

// Импорт маршрутов модулей
import authRoutes from './modules/auth/auth.routes';
import usersRoutes from './modules/users/users.routes';
import groupsRoutes from './modules/groups/groups.routes';
import specialtiesRoutes from './modules/specialties/specialties.routes';
import subjectsRoutes from './modules/subjects/subjects.routes';
import scheduleRoutes from './modules/schedule/schedule.routes';
import attendanceRoutes from './modules/attendance/attendance.routes';
import gradesRoutes from './modules/grades/grades.routes';
import announcementsRoutes from './modules/announcements/announcements.routes';
import dashboardRoutes from './modules/dashboard/dashboard.routes';
import reportsRoutes from './modules/reports/reports.routes';

const app = express();

// ==================== SECURITY ====================
app.use(helmet());
const isDev = process.env.NODE_ENV !== 'production';
const allowedOrigins = (process.env.ALLOWED_ORIGINS ?? 'http://localhost:3001').split(',');

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (isDev && /^http:\/\/localhost(:\d+)?$/.test(origin)) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error(`Origin ${origin} not allowed by CORS`));
    },
    credentials: true,
  }),
);

// ==================== ОБЩИЕ MIDDLEWARE ====================
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

// Статические файлы (аватары и загруженные документы)
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// ==================== SWAGGER ====================
app.use(
  '/api/docs',
  swaggerUi.serve,
  swaggerUi.setup(swaggerSpec, {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'College API Documentation',
  }),
);
app.get('/api/docs.json', (_req, res) => res.json(swaggerSpec));

// ==================== HEALTH CHECK ====================
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ==================== API ROUTES ====================
const API_PREFIX = '/api/v1';

app.use(`${API_PREFIX}/auth`, authRoutes);
app.use(`${API_PREFIX}/users`, usersRoutes);
app.use(`${API_PREFIX}/groups`, groupsRoutes);
app.use(`${API_PREFIX}/specialties`, specialtiesRoutes);
app.use(`${API_PREFIX}/subjects`, subjectsRoutes);
app.use(`${API_PREFIX}/schedule`, scheduleRoutes);
app.use(`${API_PREFIX}/attendance`, attendanceRoutes);
app.use(`${API_PREFIX}/grades`, gradesRoutes);
app.use(`${API_PREFIX}/announcements`, announcementsRoutes);
app.use(`${API_PREFIX}/dashboard`, dashboardRoutes);
app.use(`${API_PREFIX}/reports`, reportsRoutes);

// 404 для незарегистрированных маршрутов
app.use((_req, res) => {
  res.status(404).json({
    success: false,
    error: { code: 'NOT_FOUND', message: 'Маршрут не найден' },
  });
});

// Глобальный обработчик ошибок — всегда последний
app.use(errorHandler);

export default app;
