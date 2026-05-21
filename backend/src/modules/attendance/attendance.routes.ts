import { Router } from 'express';
import { attendanceService, markAttendanceSchema } from './attendance.service';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { ApiResponse } from '../../utils/ApiResponse';

const router = Router();
router.use(authenticate);

// Отметка посещаемости — только преподаватель
router.post('/mark', authorize('TEACHER'), validateBody(markAttendanceSchema), async (req, res) => {
  const records = await attendanceService.markAttendance(req.user!.id, req.body);
  ApiResponse.success(res, records, 'Посещаемость отмечена');
});

// Посещаемость конкретного студента
router.get('/student/:studentId', async (req, res) => {
  const result = await attendanceService.getStudentAttendance(req.params.studentId, req.query as any);
  ApiResponse.success(res, result);
});

// Моя посещаемость (студент)
router.get('/my', authorize('STUDENT'), async (req, res) => {
  const result = await attendanceService.getStudentAttendance(req.user!.id, req.query as any);
  ApiResponse.success(res, result);
});

// Посещаемость группы на занятии
router.get('/entry/:entryId', async (req, res) => {
  const { date } = req.query as { date?: string };
  if (!date) {
    ApiResponse.error(res, 400, 'Параметр date обязателен', 'BAD_REQUEST');
    return;
  }
  const result = await attendanceService.getGroupAttendance(req.params.entryId, date);
  ApiResponse.success(res, result);
});

// Статистика по группе
router.get('/group/:groupId/stats', async (req, res) => {
  const stats = await attendanceService.getGroupStats(req.params.groupId, req.query as any);
  ApiResponse.success(res, stats);
});

export default router;
