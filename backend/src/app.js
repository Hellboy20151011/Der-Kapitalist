import express from 'express';
import { authRouter } from './routes/auth.js';
import { stateRouter } from './routes/state.js';
import { economyRouter } from './routes/economy.js';
import { marketRouter } from './routes/market.js';
import { devRouter } from './routes/dev.js';

export function createApp() {
  const app = express();
  app.use(express.json());

  app.get('/health', (_, res) => res.json({ ok: true }));

  app.use('/auth', authRouter);
  app.use('/state', stateRouter);
  app.use('/economy', economyRouter);
  app.use('/market', marketRouter);
  app.use('/dev', devRouter);

  return app;
}