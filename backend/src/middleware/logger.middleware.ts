import morgan, { StreamOptions } from 'morgan';

const stream: StreamOptions = {
  write: (message) => console.info(message.trim()),
};

// dev-формат в разработке, combined в production
export const requestLogger = morgan(
  process.env.NODE_ENV === 'development' ? 'dev' : 'combined',
  { stream },
);
