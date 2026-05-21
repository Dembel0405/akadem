import { Router } from 'express';
import { gradesService, createGradeSchema } from './grades.service';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { ApiResponse } from '../../utils/ApiResponse';

const router = Router();
router.use(authenticate);

// Мои оценки (студент)
router.get('/my', authorize('STUDENT'), async (req, res) => {
  const result = await gradesService.getStudentGrades(req.user!.id, req.query.subjectId as string);
  ApiResponse.success(res, result);
});

// Оценки конкретного студента
router.get('/student/:studentId', authorize('TEACHER', 'CURATOR', 'ADMIN'), async (req, res) => {
  const result = await gradesService.getStudentGrades(req.params.studentId, req.query.subjectId as string);
  ApiResponse.success(res, result);
});

// Журнал группы по дисциплине
router.get('/group/:groupId/subject/:subjectId', authorize('TEACHER', 'CURATOR', 'ADMIN'), async (req, res) => {
  const result = await gradesService.getGroupGrades(req.user!.id, req.params.groupId, req.params.subjectId);
  ApiResponse.success(res, result);
});

// Выставить оценку
router.post('/', authorize('TEACHER', 'ADMIN'), validateBody(createGradeSchema), async (req, res) => {
  const grade = await gradesService.create(req.user!.id, req.body);
  ApiResponse.created(res, grade, 'Оценка выставлена');
});

// Изменить оценку
router.patch('/:id', authorize('TEACHER', 'ADMIN'), validateBody(createGradeSchema.partial()), async (req, res) => {
  const grade = await gradesService.update(req.params.id, req.user!.id, req.body);
  ApiResponse.success(res, grade, 'Оценка обновлена');
});

// Удалить оценку
router.delete('/:id', authorize('TEACHER', 'ADMIN'), async (req, res) => {
  await gradesService.delete(req.params.id, req.user!.id);
  ApiResponse.noContent(res);
});

export default router;
