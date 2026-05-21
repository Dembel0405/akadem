import { PrismaClient, Role, DayOfWeek, WeekType, GradeType, AttendanceStatus } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

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

  const SALT_ROUNDS = 10;

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

  // ==================== АДМИНИСТРАТОР ====================
  console.info('Создание пользователей...');
  const admin = await prisma.user.create({
    data: {
      email: 'admin@college.kz',
      passwordHash: await bcrypt.hash('Admin123!', SALT_ROUNDS),
      firstName: 'Администратор',
      lastName: 'Системы',
      middleName: 'Главный',
      role: Role.ADMIN,
      phone: '+7 (701) 000-00-00',
    },
  });

  // ==================== ПРЕПОДАВАТЕЛИ ====================
  const teacher1 = await prisma.user.create({
    data: {
      email: 'teacher@college.kz',
      passwordHash: await bcrypt.hash('Teacher123!', SALT_ROUNDS),
      firstName: 'Мария',
      lastName: 'Иванова',
      middleName: 'Сергеевна',
      role: Role.TEACHER,
      phone: '+7 (702) 111-11-11',
    },
  });

  const teacher2 = await prisma.user.create({
    data: {
      email: 'teacher2@college.kz',
      passwordHash: await bcrypt.hash('Teacher123!', SALT_ROUNDS),
      firstName: 'Алексей',
      lastName: 'Петров',
      middleName: 'Николаевич',
      role: Role.TEACHER,
      phone: '+7 (703) 222-22-22',
    },
  });

  // ==================== КУРАТОР (создаём без группы, привяжем позже) ====================
  const curator = await prisma.user.create({
    data: {
      email: 'curator@college.kz',
      passwordHash: await bcrypt.hash('Curator123!', SALT_ROUNDS),
      firstName: 'Светлана',
      lastName: 'Кузнецова',
      middleName: 'Владимировна',
      role: Role.CURATOR,
      phone: '+7 (704) 333-33-33',
    },
  });

  // ==================== ГРУППЫ ====================
  console.info('Создание групп...');
  const group1 = await prisma.group.create({
    data: {
      name: 'ИС-23-1',
      year: 2023,
      specialtyId: specialtyIS.id,
      curatorId: curator.id,
    },
  });

  const group2 = await prisma.group.create({
    data: {
      name: 'ИС-24-1',
      year: 2024,
      specialtyId: specialtyIS.id,
    },
  });

  const group3 = await prisma.group.create({
    data: {
      name: 'ЭК-23-1',
      year: 2023,
      specialtyId: specialtyEcon.id,
    },
  });

  // ==================== СТУДЕНТЫ ====================
  const studentEmails = [
    { email: 'student@college.kz', firstName: 'Алексей', lastName: 'Смирнов', middleName: 'Дмитриевич' },
    { email: 'student2@college.kz', firstName: 'Анна', lastName: 'Козлова', middleName: 'Павловна' },
    { email: 'student3@college.kz', firstName: 'Дмитрий', lastName: 'Новиков', middleName: 'Андреевич' },
    { email: 'student4@college.kz', firstName: 'Екатерина', lastName: 'Морозова', middleName: 'Ивановна' },
    { email: 'student5@college.kz', firstName: 'Иван', lastName: 'Волков', middleName: 'Сергеевич' },
  ];

  const students = await Promise.all(
    studentEmails.map((s, index) =>
      prisma.user.create({
        data: {
          email: s.email,
          passwordHash: bcrypt.hashSync('Student123!', SALT_ROUNDS),
          firstName: s.firstName,
          lastName: s.lastName,
          middleName: s.middleName,
          role: Role.STUDENT,
          studentGroupId: index < 3 ? group1.id : group2.id,
        },
      }),
    ),
  );

  // ==================== ДИСЦИПЛИНЫ ====================
  console.info('Создание дисциплин...');
  const subjects = await Promise.all([
    prisma.subject.create({
      data: { name: 'Разработка веб-приложений', code: 'МДК.01.01', hoursTotal: 144, credits: 4 },
    }),
    prisma.subject.create({
      data: { name: 'Основы программирования', code: 'МДК.01.02', hoursTotal: 108, credits: 3 },
    }),
    prisma.subject.create({
      data: { name: 'Базы данных', code: 'МДК.02.01', hoursTotal: 108, credits: 3 },
    }),
    prisma.subject.create({
      data: { name: 'Математика', code: 'ОП.01', hoursTotal: 72, credits: 2 },
    }),
    prisma.subject.create({
      data: { name: 'Физическая культура', code: 'ОУД.10', hoursTotal: 80, credits: 0 },
    }),
  ]);

  const [webDev, progBasics, databases, math, phys] = subjects;

  // ==================== РАСПИСАНИЕ ====================
  console.info('Создание расписания...');
  const scheduleData = [
    // Понедельник — группа ИС-23-1
    { dayOfWeek: DayOfWeek.MONDAY, startTime: '08:00', endTime: '09:35', room: '201', subjectId: webDev.id, teacherId: teacher1.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.MONDAY, startTime: '09:50', endTime: '11:25', room: '301', subjectId: databases.id, teacherId: teacher2.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.MONDAY, startTime: '11:40', endTime: '13:15', room: '101', subjectId: math.id, teacherId: teacher2.id, groupId: group1.id },
    // Вторник — группа ИС-23-1
    { dayOfWeek: DayOfWeek.TUESDAY, startTime: '08:00', endTime: '09:35', room: '202', subjectId: progBasics.id, teacherId: teacher1.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.TUESDAY, startTime: '09:50', endTime: '11:25', room: 'Спортзал', subjectId: phys.id, teacherId: teacher2.id, groupId: group1.id },
    // Среда — группа ИС-23-1
    { dayOfWeek: DayOfWeek.WEDNESDAY, startTime: '08:00', endTime: '09:35', room: '201', subjectId: webDev.id, teacherId: teacher1.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.WEDNESDAY, startTime: '09:50', endTime: '11:25', room: '301', subjectId: databases.id, teacherId: teacher2.id, groupId: group1.id },
    // Четверг — группа ИС-23-1
    { dayOfWeek: DayOfWeek.THURSDAY, startTime: '08:00', endTime: '09:35', room: '202', subjectId: progBasics.id, teacherId: teacher1.id, groupId: group1.id },
    { dayOfWeek: DayOfWeek.THURSDAY, startTime: '09:50', endTime: '11:25', room: '101', subjectId: math.id, teacherId: teacher2.id, groupId: group1.id },
    // Пятница — группа ИС-23-1
    { dayOfWeek: DayOfWeek.FRIDAY, startTime: '08:00', endTime: '09:35', room: '201', subjectId: webDev.id, teacherId: teacher1.id, groupId: group1.id },
  ];

  const scheduleEntries = await Promise.all(
    scheduleData.map((entry) => prisma.scheduleEntry.create({ data: entry })),
  );

  // ==================== ПОСЕЩАЕМОСТЬ ====================
  console.info('Создание записей посещаемости...');
  // Создаём посещаемость за последние 2 недели для первых 3 студентов группы ИС-23-1
  const today = new Date();
  const attendanceDates = Array.from({ length: 10 }, (_, i) => {
    const d = new Date(today);
    d.setDate(d.getDate() - i - 1);
    return d;
  }).filter((d) => d.getDay() !== 0 && d.getDay() !== 6); // только рабочие дни

  const studentsGroup1 = students.slice(0, 3);
  const mondayEntry = scheduleEntries[0]; // первый урок понедельника

  for (const student of studentsGroup1) {
    for (const date of attendanceDates.slice(0, 5)) {
      await prisma.attendance.upsert({
        where: {
          studentId_scheduleEntryId_date: {
            studentId: student.id,
            scheduleEntryId: mondayEntry.id,
            date: new Date(date.toDateString()),
          },
        },
        update: {},
        create: {
          studentId: student.id,
          scheduleEntryId: mondayEntry.id,
          date: new Date(date.toDateString()),
          // Один студент иногда отсутствует
          status: student.email === 'student3@college.kz' && Math.random() > 0.6
            ? AttendanceStatus.ABSENT
            : AttendanceStatus.PRESENT,
        },
      });
    }
  }

  // ==================== ОЦЕНКИ ====================
  console.info('Создание оценок...');
  const gradeData = [
    { studentIdx: 0, subjectId: webDev.id, value: 5, type: GradeType.CURRENT },
    { studentIdx: 0, subjectId: webDev.id, value: 4, type: GradeType.CONTROL },
    { studentIdx: 0, subjectId: databases.id, value: 5, type: GradeType.CURRENT },
    { studentIdx: 1, subjectId: webDev.id, value: 4, type: GradeType.CURRENT },
    { studentIdx: 1, subjectId: databases.id, value: 3, type: GradeType.CURRENT },
    { studentIdx: 1, subjectId: databases.id, value: 4, type: GradeType.CONTROL },
    { studentIdx: 2, subjectId: progBasics.id, value: 5, type: GradeType.CURRENT },
    { studentIdx: 2, subjectId: math.id, value: 4, type: GradeType.CURRENT },
    { studentIdx: 2, subjectId: math.id, value: 5, type: GradeType.EXAM },
    { studentIdx: 3, subjectId: webDev.id, value: 3, type: GradeType.CURRENT },
    { studentIdx: 3, subjectId: databases.id, value: 4, type: GradeType.CURRENT },
    { studentIdx: 4, subjectId: progBasics.id, value: 5, type: GradeType.CURRENT },
    { studentIdx: 4, subjectId: math.id, value: 5, type: GradeType.EXAM },
  ];

  await Promise.all(
    gradeData.map(({ studentIdx, subjectId, value, type }) =>
      prisma.grade.create({
        data: {
          studentId: students[studentIdx].id,
          subjectId,
          teacherId: teacher1.id,
          value,
          type,
          date: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
        },
      }),
    ),
  );

  // ==================== ОБЪЯВЛЕНИЯ ====================
  console.info('Создание объявлений...');
  await prisma.announcement.createMany({
    data: [
      {
        title: 'Изменение расписания на следующей неделе',
        content: 'Уважаемые студенты и преподаватели! В связи с проведением олимпиады в среду 29 мая занятия переносятся. Обновлённое расписание опубликовано в системе.',
        authorId: admin.id,
        isPinned: true,
        targetRoles: ['ALL'],
      },
      {
        title: 'Сессия: расписание экзаменов',
        content: 'Расписание экзаменационной сессии утверждено. Первый экзамен состоится 10 июня. Подробное расписание доступно в разделе "Расписание".',
        authorId: admin.id,
        isPinned: false,
        targetRoles: ['STUDENTS', 'TEACHERS'],
      },
      {
        title: 'Педсовет — 28 мая',
        content: 'Уважаемые коллеги! 28 мая в 15:00 в актовом зале состоится педагогический совет. Присутствие обязательно.',
        authorId: admin.id,
        isPinned: false,
        targetRoles: ['TEACHERS', 'ADMINS'],
      },
      {
        title: 'Конкурс студенческих проектов',
        content: 'Приглашаем студентов принять участие в ежегодном конкурсе IT-проектов. Приём заявок до 1 июня. Победители получат именные дипломы и ценные призы.',
        authorId: teacher1.id,
        isPinned: false,
        targetRoles: ['STUDENTS'],
      },
    ],
  });

  console.info('✅ База данных успешно заполнена тестовыми данными!');
  console.info('');
  console.info('Тестовые аккаунты:');
  console.info('  Администратор:  admin@college.kz    / Admin123!');
  console.info('  Преподаватель:  teacher@college.kz  / Teacher123!');
  console.info('  Студент:        student@college.kz  / Student123!');
  console.info('  Куратор:        curator@college.kz  / Curator123!');
}

main()
  .catch((e) => {
    console.error('Ошибка при заполнении базы данных:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
