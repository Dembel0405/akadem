import app from './app';
import { prisma } from './config/database';

const PORT = parseInt(process.env.PORT ?? '3000', 10);

async function startServer() {
  try {
    // Проверяем соединение с БД перед запуском
    await prisma.$connect();
    console.info('✅ Подключение к базе данных установлено');

    app.listen(PORT, () => {
      console.info(`🚀 Сервер запущен на порту ${PORT}`);
      console.info(`📖 Swagger UI: http://localhost:${PORT}/api/docs`);
      console.info(`🌍 Режим: ${process.env.NODE_ENV ?? 'development'}`);
    });
  } catch (error) {
    console.error('❌ Ошибка запуска сервера:', error);
    await prisma.$disconnect();
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.info('SIGTERM получен. Завершение работы...');
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.info('SIGINT получен. Завершение работы...');
  await prisma.$disconnect();
  process.exit(0);
});

startServer();
