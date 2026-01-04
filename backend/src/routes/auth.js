import express from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { pool } from '../db.js';
import { config } from '../config.js';

export const authRouter = express.Router();

const authSchema = z.object({
  email: z.string().email().max(200),
  password: z.string().min(6).max(200)
});

function signToken(userId) {
  return jwt.sign({}, config.jwtSecret, {
    subject: userId,
    expiresIn: config.jwtExpiresIn
  });
}

async function seedNewPlayer(client, userId) {
  // Start with 100 coins to be able to build buildings and start production
  await client.query(`INSERT INTO player_state(user_id, coins, last_tick_at) VALUES ($1, 100, now())`, [userId]);

  // Start-Inventar
  const resources = ['water', 'wood', 'stone'];
  for (const r of resources) {
    await client.query(
      `INSERT INTO inventory(user_id, resource_type, amount) VALUES ($1, $2, 0)
       ON CONFLICT DO NOTHING`,
      [userId, r]
    );
  }

  // Start-Gebäude (1 pro Typ)
  const buildings = ['well', 'lumberjack', 'sandgrube'];
  for (const b of buildings) {
    await client.query(
      `INSERT INTO buildings(user_id, building_type, level) VALUES ($1, $2, 1)
       ON CONFLICT (user_id, building_type) DO NOTHING`,
      [userId, b]
    );
  }
}

authRouter.post('/register', async (req, res) => {
  const parsed = authSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const { email, password } = parsed.data;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const hash = await bcrypt.hash(password, 12);

    const uRes = await client.query(
      `INSERT INTO users(email, password_hash) VALUES ($1, $2) RETURNING id`,
      [email.toLowerCase(), hash]
    );

    const userId = uRes.rows[0].id;
    await seedNewPlayer(client, userId);

    await client.query('COMMIT');
    return res.json({ token: signToken(userId) });
  } catch (e) {
    await client.query('ROLLBACK');
    // Unique violation
    if (String(e?.code) === '23505') return res.status(409).json({ error: 'email_exists' });
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});

authRouter.post('/login', async (req, res) => {
  const parsed = authSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const { email, password } = parsed.data;

  const uRes = await pool.query(
    `SELECT id, password_hash FROM users WHERE email = $1`,
    [email.toLowerCase()]
  );

  if (uRes.rowCount === 0) return res.status(401).json({ error: 'invalid_credentials' });

  const { id, password_hash } = uRes.rows[0];
  const ok = await bcrypt.compare(password, password_hash);
  if (!ok) return res.status(401).json({ error: 'invalid_credentials' });

  return res.json({ token: signToken(id) });
});