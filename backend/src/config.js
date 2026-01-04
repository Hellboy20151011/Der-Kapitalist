import 'dotenv/config';
import { logger } from './logger.js';

export const config = {
  port: Number(process.env.PORT ?? 3000),
  dbUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  allowedOrigins: process.env.ALLOWED_ORIGINS?.split(',').map(o => o.trim()) ?? []
};

if (!config.dbUrl) throw new Error("DATABASE_URL missing in .env");
if (!config.jwtSecret) throw new Error("JWT_SECRET missing in .env");
if (config.jwtSecret.length < 32) {
  logger.warn("JWT_SECRET should be at least 32 characters for production security", {
    currentLength: config.jwtSecret.length,
    recommendedLength: 32
  });
}