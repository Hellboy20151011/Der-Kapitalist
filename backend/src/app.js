import express from 'express';
import cors from 'cors';
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

  app.get('/health', (_, res) => res.json({ 
    ok: true, 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  }));

  app.use('/auth', authRouter);
  app.use('/state', stateRouter);
  app.use('/economy', economyRouter);
  app.use('/market', marketRouter);
  app.use('/dev', devRouter);
  app.use('/production', productionRouter);

  return app;
}