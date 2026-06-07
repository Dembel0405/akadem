import { PrismaClient, Role, DayOfWeek, WeekType, GradeType, AttendanceStatus } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const SALT_ROUNDS = 10;

function getLastWorkingDays(n: number): Date[] {
  const days: Date[] = [];
  const d = new Date();
  d.setDate(d.getDate() - 1); // start from yesterday
  while (days.length < n) {
    if (d.getDay() !== 0 && d.getDay() !== 6) days.push(new Date(d.toDateString()));
    d.setDate(d.getDate() - 1);
  }
  return days;
}

const DOW_TO_JS: Record<string, number> = {
  MONDAY: 1, TUESDAY: 2, WEDNESDAY: 3, THURSDAY: 4, FRIDAY: 5, SATURDAY: 6,
};

function pickAttendance(presentRate: number): AttendanceStatus {
  const r = Math.random();
  if (r < presentRate) return AttendanceStatus.PRESENT;
  if (r < presentRate + 0.08) return AttendanceStatus.LATE;
  if (r < presentRate + 0.13) return AttendanceStatus.EXCUSED;
  return AttendanceStatus.ABSENT;
}

function randomGrade(performance: number): number {
  const r = Math.random();
  if (performance >= 0.85) return r < 0.55 ? 5 : r < 0.9 ? 4 : 3;
  if (performance >= 0.65) return r < 0.25 ? 5 : r < 0.65 ? 4 : r < 0.92 ? 3 : 2;
  return r < 0.08 ? 5 : r < 0.35 ? 4 : r < 0.78 ? 3 : 2;
}

function randomPastDate(maxDaysAgo: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - Math.floor(Math.random() * maxDaysAgo));
  return d;
}

async function main() {
  console.info('Очистка базы данных...');
  await prisma.attendance.deleteMany();
  await prisma.grade.deleteMany();
  await prisma.scheduleEntry.deleteMany();
  await prisma.announcement.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.user.deleteMany();
  await prisma.group.deleteMany();
  await prisma.specialty.deleteMany();
  await prisma.subject.deleteMany();

  // ==================== СПЕЦИАЛЬНОСТИ ====================
  console.info('Создание специальностей...');
  const specialtyIS = await prisma.specialty.create({
    data: {
      name: 'Информационные системы и программирование',
      code: '09.02.07',
      description: 'Подготовка специалистов в области разработки программного обеспечения',
    },
  });
  const specialtyEcon = await prisma.specialty.create({
    data: {
      name: 'Экономика и бухгалтерский учёт',
      code: '38.02.01',
      description: 'Подготовка специалистов в области экономики и финансов',
    },
  });

  // ==================== ПОЛЬЗОВАТЕЛИ ====================
  console.info('Создание пользователей...');

  const adminHash    = await bcrypt.hash('Admin123!',   SALT_ROUNDS);
  const teacherHash  = await bcrypt.hash('Teacher123!', SALT_ROUNDS);
  const curatorHash  = await bcrypt.hash('Curator123!', SALT_ROUNDS);
  const studentHash  = await bcrypt.hash('Student123!', SALT_ROUNDS);

  const admin = await prisma.user.create({
    data: {
      email: 'admin@college.kz', passwordHash: adminHash,
      firstName: 'Администратор', lastName: 'Системы', middleName: 'Главный',
      role: Role.ADMIN, phone: '+7 (701) 000-00-00',
    },
  });

  const teacher1 = await prisma.user.create({
    data: {
      email: 'teacher@college.kz', passwordHash: teacherHash,
      firstName: 'Мария', lastName: 'Иванова', middleName: 'Сергеевна',
      role: Role.TEACHER, phone: '+7 (702) 111-11-11',
    },
  });
  const teacher2 = await prisma.user.create({
    data: {
      email: 'teacher2@college.kz', passwordHash: teacherHash,
      firstName: 'Алексей', lastName: 'Петров', middleName: 'Николаевич',
      role: Role.TEACHER, phone: '+7 (703) 222-22-22',
    },
  });
  const teacher3 = await prisma.user.create({
    data: {
      email: 'teacher3@college.kz', passwordHash: teacherHash,
      firstName: 'Наргиза', lastName: 'Сиддикова', middleName: 'Рустамовна',
      role: Role.TEACHER, phone: '+7 (704) 333-33-33',
    },
  });

  const curator1 = await prisma.user.create({
    data: {
      email: 'curator@college.kz', passwordHash: curatorHash,
      firstName: 'Светлана', lastName: 'Кузнецова', middleName: 'Владимировна',
      role: Role.CURATOR, phone: '+7 (705) 444-44-44',
    },
  });
  const curator2 = await prisma.user.create({
    data: {
      email: 'curator2@college.kz', passwordHash: curatorHash,
      firstName: 'Дамир', lastName: 'Ахметов', middleName: 'Сейткалиевич',
      role: Role.CURATOR, phone: '+7 (706) 555-55-55',
    },
  });

  // ==================== ГРУППЫ ====================
  console.info('Создание групп...');
  const group1 = await prisma.group.create({
    data: { name: 'ИС-23-1', year: 2023, specialtyId: specialtyIS.id, curatorId: curator1.id },
  });
  const group2 = await prisma.group.create({
    data: { name: 'ИС-24-1', year: 2024, specialtyId: specialtyIS.id },
  });
  const group3 = await prisma.group.create({
    data: { name: 'ЭК-23-1', year: 2023, specialtyId: specialtyEcon.id, curatorId: curator2.id },
  });

  // ==================== СТУДЕНТЫ ====================
  const studentDefs = [
    // group1 — ИС-23-1 (8 студентов)
    { email: 'student@college.kz',   fn: 'Алексей',   ln: 'Смирнов',    mn: 'Дмитриевич',  gid: group1.id, perf: 0.90 },
    { email: 'student2@college.kz',  fn: 'Анна',      ln: 'Козлова',    mn: 'Павловна',    gid: group1.id, perf: 0.80 },
    { email: 'student3@college.kz',  fn: 'Дмитрий',   ln: 'Новиков',    mn: 'Андреевич',   gid: group1.id, perf: 0.70 },
    { email: 'student4@college.kz',  fn: 'Екатерина', ln: 'Морозова',   mn: 'Ивановна',    gid: group1.id, perf: 0.88 },
    { email: 'student5@college.kz',  fn: 'Иван',      ln: 'Волков',     mn: 'Сергеевич',   gid: group1.id, perf: 0.75 },
    { email: 'student6@college.kz',  fn: 'Ксения',    ln: 'Лебедева',   mn: 'Олеговна',    gid: group1.id, perf: 0.92 },
    { email: 'student7@college.kz',  fn: 'Михаил',    ln: 'Зайцев',     mn: 'Петрович',    gid: group1.id, perf: 0.65 },
    { email: 'student8@college.kz',  fn: 'Наталья',   ln: 'Орлова',     mn: 'Викторовна',  gid: group1.id, perf: 0.85 },
    // group2 — ИС-24-1 (6 студентов)
    { email: 'student9@college.kz',  fn: 'Артём',     ln: 'Попов',      mn: 'Игоревич',    gid: group2.id, perf: 0.87 },
    { email: 'student10@college.kz', fn: 'Валерия',   ln: 'Никитина',   mn: 'Дмитриевна',  gid: group2.id, perf: 0.78 },
    { email: 'student11@college.kz', fn: 'Денис',     ln: 'Соколов',    mn: 'Александрович',gid: group2.id, perf: 0.60 },
    { email: 'student12@college.kz', fn: 'Ирина',     ln: 'Фёдорова',   mn: 'Николаевна',  gid: group2.id, perf: 0.93 },
    { email: 'student13@college.kz', fn: 'Кирилл',    ln: 'Павлов',     mn: 'Романович',   gid: group2.id, perf: 0.72 },
    { email: 'student14@college.kz', fn: 'Лариса',    ln: 'Семёнова',   mn: 'Борисовна',   gid: group2.id, perf: 0.83 },
    // group3 — ЭК-23-1 (6 студентов)
    { email: 'student15@college.kz', fn: 'Максим',    ln: 'Голубев',    mn: 'Евгеньевич',  gid: group3.id, perf: 0.82 },
    { email: 'student16@college.kz', fn: 'Ольга',     ln: 'Кузьмина',   mn: 'Андреевна',   gid: group3.id, perf: 0.91 },
    { email: 'student17@college.kz', fn: 'Павел',     ln: 'Тихонов',    mn: 'Юрьевич',     gid: group3.id, perf: 0.68 },
    { email: 'student18@college.kz', fn: 'Светлана',  ln: 'Воробьёва',  mn: 'Игоревна',    gid: group3.id, perf: 0.86 },
    { email: 'student19@college.kz', fn: 'Тимур',     ln: 'Белов',      mn: 'Маратович',   gid: group3.id, perf: 0.74 },
    { email: 'student20@college.kz', fn: 'Юлия',      ln: 'Романова',   mn: 'Сергеевна',   gid: group3.id, perf: 0.95 },
  ];

  const students = await Promise.all(
    studentDefs.map((s) =>
      prisma.user.create({
        data: {
          email: s.email, passwordHash: studentHash,
          firstName: s.fn, lastName: s.ln, middleName: s.mn,
          role: Role.STUDENT, studentGroupId: s.gid,
        },
      }),
    ),
  );

  // ==================== ДИСЦИПЛИНЫ ====================
  console.info('Создание дисциплин...');
  const [webDev, progBasics, databases, math, phys, econTheory, accounting, finance] =
    await Promise.all([
      prisma.subject.create({ data: { name: 'Разработка веб-приложений', code: 'МДК.01.01', hoursTotal: 144, credits: 4 } }),
      prisma.subject.create({ data: { name: 'Основы программирования',   code: 'МДК.01.02', hoursTotal: 108, credits: 3 } }),
      prisma.subject.create({ data: { name: 'Базы данных',               code: 'МДК.02.01', hoursTotal: 108, credits: 3 } }),
      prisma.subject.create({ data: { name: 'Математика',                code: 'ОП.01',     hoursTotal: 72,  credits: 2 } }),
      prisma.subject.create({ data: { name: 'Физическая культура',       code: 'ОУД.10',    hoursTotal: 80,  credits: 0 } }),
      prisma.subject.create({ data: { name: 'Экономическая теория',      code: 'ЭК.01',     hoursTotal: 108, credits: 3 } }),
      prisma.subject.create({ data: { name: 'Бухгалтерский учёт',        code: 'ЭК.02',     hoursTotal: 144, credits: 4 } }),
      prisma.subject.create({ data: { name: 'Финансы и кредит',          code: 'ЭК.03',     hoursTotal: 72,  credits: 2 } }),
    ]);

  // ==================== РАСПИСАНИЕ ====================
  console.info('Создание расписания...');
  type EntryDef = {
    dayOfWeek: DayOfWeek; startTime: string; endTime: string;
    room: string; subjectId: string; teacherId: string; groupId: string;
  };

  const scheduleDefs: EntryDef[] = [
    // ── ИС-23-1 ──
    { dayOfWeek: DayOfWeek.MONDAY,    startTime: '08:00', endTime: '09:35', room: '201', subjectId: webDev.id,     teacherId: teacher1.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.MONDAY,    startTime: '09:50', endTime: '11:25', room: '301', subjectId: databases.id,  teacherId: teacher2.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.MONDAY,    startTime: '11:40', endTime: '13:15', room: '101', subjectId: math.id,       teacherId: teacher2.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.TUESDAY,   startTime: '08:00', endTime: '09:35', room: '202', subjectId: progBasics.id, teacherId: teacher1.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.TUESDAY,   startTime: '09:50', endTime: '11:25', room: 'СЗ',  subjectId: phys.id,       teacherId: teacher2.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.WEDNESDAY, startTime: '08:00', endTime: '09:35', room: '201', subjectId: webDev.id,     teacherId: teacher1.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.WEDNESDAY, startTime: '09:50', endTime: '11:25', room: '301', subjectId: databases.id,  teacherId: teacher2.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.THURSDAY,  startTime: '08:00', endTime: '09:35', room: '202', subjectId: progBasics.id, teacherId: teacher1.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.THURSDAY,  startTime: '09:50', endTime: '11:25', room: '101', subjectId: math.id,       teacherId: teacher2.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.FRIDAY,    startTime: '08:00', endTime: '09:35', room: '201', subjectId: webDev.id,     teacherId: teacher1.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.FRIDAY,    startTime: '09:50', endTime: '11:25', room: '301', subjectId: databases.id,  teacherId: teacher2.id, groupId: group1.id },

    // ── ИС-24-1 ──
    { dayOfWeek: DayOfWeek.MONDAY,    startTime: '08:00', endTime: '09:35', room: '203', subjectId: progBasics.id, teacherId: teacher1.id, groupId: group2.id },
    { dayOfWeek: DayOfWeek.MONDAY,    startTime: '09:50', endTime: '11:25', room: '102', subjectId: math.id,       teacherId: teacher2.id, groupId: group2.id },
    { dayOfWeek: DayOfWeek.TUESDAY,   startTime: '08:00', endTime: '09:35', room: '204', subjectId: webDev.id,     teacherId: teacher1.id, groupId: group2.id },
    { dayOfWeek: DayOfWeek.TUESDAY,   startTime: '09:50', endTime: '11:25', room: 'СЗ',  subjectId: phys.id,       teacherId: teacher2.id, groupId: group2.id },
    { dayOfWeek: DayOfWeek.WEDNESDAY, startTime: '08:00', endTime: '09:35', room: '302', subjectId: databases.id,  teacherId: teacher2.id, groupId: group2.id },
    { dayOfWeek: DayOfWeek.WEDNESDAY, startTime: '09:50', endTime: '11:25', room: '203', subjectId: progBasics.id, teacherId: teacher1.id, groupId: group2.id },
    { dayOfWeek: DayOfWeek.THURSDAY,  startTime: '08:00', endTime: '09:35', room: '102', subjectId: math.id,       teacherId: teacher2.id, groupId: group2.id },
    { dayOfWeek: DayOfWeek.THURSDAY,  startTime: '09:50', endTime: '11:25', room: '204', subjectId: webDev.id,     teacherId: teacher1.id, groupId: group2.id },
    { dayOfWeek: DayOfWeek.FRIDAY,    startTime: '08:00', endTime: '09:35', room: '302', subjectId: databases.id,  teacherId: teacher2.id, groupId: group2.id },

    // ── ЭК-23-1 ──
    { dayOfWeek: DayOfWeek.MONDAY,    startTime: '08:00', endTime: '09:35', room: '401', subjectId: econTheory.id, teacherId: teacher3.id, groupId: group3.id },
    { dayOfWeek: DayOfWeek.MONDAY,    startTime: '09:50', endTime: '11:25', room: '402', subjectId: accounting.id, teacherId: teacher3.id, groupId: group3.id },
    { dayOfWeek: DayOfWeek.TUESDAY,   startTime: '08:00', endTime: '09:35', room: '403', subjectId: finance.id,    teacherId: teacher3.id, groupId: group3.id },
    { dayOfWeek: DayOfWeek.TUESDAY,   startTime: '09:50', endTime: '11:25', room: '401', subjectId: econTheory.id, teacherId: teacher3.id, groupId: group3.id },
    { dayOfWeek: DayOfWeek.WEDNESDAY, startTime: '08:00', endTime: '09:35', room: '402', subjectId: accounting.id, teacherId: teacher3.id, groupId: group3.id },
    { dayOfWeek: DayOfWeek.WEDNESDAY, startTime: '09:50', endTime: '11:25', room: '101', subjectId: math.id,       teacherId: teacher2.id, groupId: group3.id },
    { dayOfWeek: DayOfWeek.THURSDAY,  startTime: '08:00', endTime: '09:35', room: '403', subjectId: finance.id,    teacherId: teacher3.id, groupId: group3.id },
    { dayOfWeek: DayOfWeek.THURSDAY,  startTime: '09:50', endTime: '11:25', room: '101', subjectId: math.id,       teacherId: teacher2.id, groupId: group3.id },
    { dayOfWeek: DayOfWeek.FRIDAY,    startTime: '08:00', endTime: '09:35', room: '401', subjectId: econTheory.id, teacherId: teacher3.id, groupId: group3.id },
    { dayOfWeek: DayOfWeek.FRIDAY,    startTime: '09:50', endTime: '11:25', room: '402', subjectId: accounting.id, teacherId: teacher3.id, groupId: group3.id },
  ];

  const scheduleEntries = await Promise.all(
    scheduleDefs.map((d) => prisma.scheduleEntry.create({ data: d })),
  );

  // ==================== ПОСЕЩАЕМОСТЬ ====================
  console.info('Создание записей посещаемости...');
  const workingDays = getLastWorkingDays(20);

  const attendanceRecords: {
    studentId: string; scheduleEntryId: string; date: Date; status: AttendanceStatus;
  }[] = [];

  for (let si = 0; si < studentDefs.length; si++) {
    const student = students[si];
    const groupId = studentDefs[si].gid;
    const perf    = studentDefs[si].perf;
    const presentRate = perf * 0.9 + 0.05; // 0.635..0.905

    const groupEntries = scheduleEntries.filter((e, idx) => scheduleDefs[idx].groupId === groupId);

    for (const entry of groupEntries) {
      const entryDow = DOW_TO_JS[scheduleDefs[scheduleEntries.indexOf(entry)].dayOfWeek];
      for (const date of workingDays) {
        if (date.getDay() !== entryDow) continue;
        attendanceRecords.push({
          studentId: student.id,
          scheduleEntryId: entry.id,
          date,
          status: pickAttendance(presentRate),
        });
      }
    }
  }

  await prisma.attendance.createMany({ data: attendanceRecords, skipDuplicates: true });
  console.info(`  → ${attendanceRecords.length} записей посещаемости`);

  // ==================== ОЦЕНКИ ====================
  console.info('Создание оценок...');

  // Предметы по группам
  const subjectsByGroup: Record<string, { subjectId: string; teacherId: string }[]> = {
    [group1.id]: [
      { subjectId: webDev.id,     teacherId: teacher1.id },
      { subjectId: progBasics.id, teacherId: teacher1.id },
      { subjectId: databases.id,  teacherId: teacher2.id },
      { subjectId: math.id,       teacherId: teacher2.id },
    ],
    [group2.id]: [
      { subjectId: webDev.id,     teacherId: teacher1.id },
      { subjectId: progBasics.id, teacherId: teacher1.id },
      { subjectId: databases.id,  teacherId: teacher2.id },
      { subjectId: math.id,       teacherId: teacher2.id },
    ],
    [group3.id]: [
      { subjectId: econTheory.id, teacherId: teacher3.id },
      { subjectId: accounting.id, teacherId: teacher3.id },
      { subjectId: finance.id,    teacherId: teacher3.id },
      { subjectId: math.id,       teacherId: teacher2.id },
    ],
  };

  const gradeTypes: GradeType[] = [GradeType.CURRENT, GradeType.CONTROL, GradeType.EXAM];

  const gradeRecords: {
    studentId: string; subjectId: string; teacherId: string;
    value: number; type: GradeType; date: Date;
  }[] = [];

  for (let si = 0; si < studentDefs.length; si++) {
    const student  = students[si];
    const groupId  = studentDefs[si].gid;
    const perf     = studentDefs[si].perf;
    const subjects = subjectsByGroup[groupId] ?? [];

    for (const { subjectId, teacherId } of subjects) {
      // 2–3 текущих оценки
      const currentCount = Math.floor(Math.random() * 2) + 2;
      for (let i = 0; i < currentCount; i++) {
        gradeRecords.push({
          studentId: student.id, subjectId, teacherId,
          value: randomGrade(perf), type: GradeType.CURRENT,
          date: randomPastDate(60),
        });
      }
      // 1 контрольная (80% шанс)
      if (Math.random() < 0.8) {
        gradeRecords.push({
          studentId: student.id, subjectId, teacherId,
          value: randomGrade(perf), type: GradeType.CONTROL,
          date: randomPastDate(45),
        });
      }
      // 1 экзамен (50% шанс)
      if (Math.random() < 0.5) {
        gradeRecords.push({
          studentId: student.id, subjectId, teacherId,
          value: randomGrade(perf), type: GradeType.EXAM,
          date: randomPastDate(30),
        });
      }
    }
  }

  await prisma.grade.createMany({ data: gradeRecords });
  console.info(`  → ${gradeRecords.length} оценок`);

  // ==================== ОБЪЯВЛЕНИЯ ====================
  console.info('Создание объявлений...');
  await prisma.announcement.createMany({
    data: [
      {
        title: 'Изменение расписания на следующей неделе',
        content: 'В связи с проведением олимпиады в среду занятия переносятся. Обновлённое расписание опубликовано в системе. Просьба ознакомиться.',
        authorId: admin.id, isPinned: true, targetRoles: ['ALL'],
      },
      {
        title: 'Расписание экзаменационной сессии',
        content: 'Расписание экзаменов утверждено. Первый экзамен — 10 июня. Подробное расписание доступно в разделе «Расписание». Явка строго обязательна.',
        authorId: admin.id, isPinned: true, targetRoles: ['STUDENTS', 'TEACHERS'],
      },
      {
        title: 'Педсовет — 15 июня',
        content: 'Уважаемые коллеги! 15 июня в 15:00 в актовом зале состоится педагогический совет. Присутствие обязательно. Повестка будет направлена на корпоративную почту.',
        authorId: admin.id, isPinned: false, targetRoles: ['TEACHERS', 'ADMINS'],
      },
      {
        title: 'Конкурс студенческих IT-проектов',
        content: 'Приглашаем студентов специальности ИС принять участие в ежегодном конкурсе. Приём заявок до 1 июля. Победители получат именные дипломы и денежные призы.',
        authorId: teacher1.id, isPinned: false, targetRoles: ['STUDENTS'],
      },
      {
        title: 'Обновление системы',
        content: 'В субботу с 23:00 до 3:00 система будет недоступна в связи с плановым техническим обслуживанием. Заранее сохраните все необходимые данные.',
        authorId: admin.id, isPinned: false, targetRoles: ['ALL'],
      },
      {
        title: 'Встреча куратора с группой ИС-23-1',
        content: 'Встреча с куратором группы состоится в пятницу в 13:30 в аудитории 205. Обсуждение итогов семестра и планов на летнюю практику. Явка обязательна.',
        authorId: curator1.id, isPinned: false, targetRoles: ['STUDENTS'],
      },
      {
        title: 'Сдача учебников в библиотеку',
        content: 'До 20 июня все студенты обязаны сдать учебники в библиотеку. Список необходимой литературы можно получить у куратора или в деканате.',
        authorId: admin.id, isPinned: false, targetRoles: ['STUDENTS'],
      },
      {
        title: 'Производственная практика — июль',
        content: 'Студенты 2-го курса направляются на производственную практику с 1 по 28 июля. Список предприятий и направления будут распределены кураторами до 25 июня.',
        authorId: admin.id, isPinned: false, targetRoles: ['STUDENTS', 'TEACHERS'],
      },
      {
        title: 'Семинар по бухгалтерскому учёту',
        content: 'Приглашаем студентов группы ЭК-23-1 на открытый семинар «Современные методы учёта». Мероприятие пройдёт 18 июня в ауд. 401. Регистрация у куратора.',
        authorId: teacher3.id, isPinned: false, targetRoles: ['STUDENTS'],
      },
      {
        title: 'Напоминание: электронные зачётные книжки',
        content: 'Все преподаватели обязаны внести итоговые оценки в систему до 25 июня. При возникновении технических сложностей обращайтесь в службу поддержки.',
        authorId: admin.id, isPinned: false, targetRoles: ['TEACHERS', 'ADMINS'],
      },
    ],
  });

  console.info('');
  console.info('✅ База данных успешно заполнена тестовыми данными!');
  console.info('');
  console.info('Тестовые аккаунты:');
  console.info('  Администратор:  admin@college.kz      / Admin123!');
  console.info('  Преподаватель:  teacher@college.kz    / Teacher123!');
  console.info('  Преподаватель:  teacher2@college.kz   / Teacher123!');
  console.info('  Преподаватель:  teacher3@college.kz   / Teacher123!');
  console.info('  Куратор:        curator@college.kz    / Curator123!');
  console.info('  Куратор:        curator2@college.kz   / Curator123!');
  console.info('  Студент:        student@college.kz    / Student123!');
  console.info('  Студент:        student15@college.kz  / Student123!  (ЭК-23-1)');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
