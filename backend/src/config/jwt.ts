export const jwtConfig = {
  accessSecret: process.env.JWT_SECRET ?? 'fallback-secret-change-in-production',
  refreshSecret: process.env.JWT_REFRESH_SECRET ?? 'fallback-refresh-secret-change-in-production',
  accessExpiresIn: (process.env.JWT_EXPIRES_IN ?? '15m') as string,
  refreshExpiresIn: (process.env.JWT_REFRESH_EXPIRES_IN ?? '7d') as string,
};
