import express from 'express';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { config } from './config.js';
import { authRouter } from './routes/auth.js';
import { stateRouter } from './routes/state.js';
import { economyRouter } from './routes/economy.js';
import { marketRouter } from './routes/market.js';
import { devRouter } from './routes/dev.js';
import { productionRouter } from './routes/production.js';

export function createApp() {
  const app = express();
  
  // CORS Configuration
  if (config.allowedOrigins.length > 0) {
    app.use(cors({
      origin: config.allowedOrigins,
      credentials: true
    }));
  } else {
    // Development mode - allow all origins
    app.use(cors());
  }
  
  app.use(express.json());

  // Rate Limiting Configuration
  // General rate limit for all endpoints
  const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'too_many_requests', message: 'Too many requests, please try again later.' }
  });

  // Stricter rate limit for authentication endpoints
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // Limit each IP to 5 login/register attempts per windowMs
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'too_many_auth_attempts', message: 'Too many authentication attempts, please try again later.' }
  });

  // Apply general rate limiter to all routes
  app.use(generalLimiter);

  app.get('/health', (_, res) => res.json({ 
    ok: true, 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  }));

  // Apply stricter rate limiter to auth routes
  app.use('/auth', authLimiter, authRouter);
  app.use('/state', stateRouter);
  app.use('/economy', economyRouter);
  app.use('/market', marketRouter);
  app.use('/dev', devRouter);
  app.use('/production', productionRouter);

  return app;
}