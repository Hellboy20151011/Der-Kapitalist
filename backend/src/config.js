import 'dotenv/config';

export const config = {
  port: Number(process.env.PORT ?? 3000),
  dbUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d'
};

if (!config.dbUrl) throw new Error("DATABASE_URL missing in .env");
if (!config.jwtSecret) throw new Error("JWT_SECRET missing in .env");