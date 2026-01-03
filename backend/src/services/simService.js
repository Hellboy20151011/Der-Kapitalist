const RESOURCES = ['water', 'wood', 'stone'];
const BUILDINGS = ['well', 'lumberjack', 'stonemason'];

// Startwerte: Produktion pro Minute bei Level 1
const BASE_RATE_PER_MIN = {
  well: 30,
  lumberjack: 15,
  stonemason: 10
};

// Wachstumsfaktor pro Level
const GROWTH = 1.15;

// Cap: max 8h Offline-Produktion
const MAX_ELAPSED_SECONDS = 8 * 60 * 60;

function ratePerSecond(buildingType, level) {
  const basePerMin = BASE_RATE_PER_MIN[buildingType] ?? 0;
  const perMin = basePerMin * Math.pow(GROWTH, Math.max(0, level - 1));
  return perMin / 60.0;
}

function producedResourceForBuilding(buildingType) {
  if (buildingType === 'well') return 'water';
  if (buildingType === 'lumberjack') return 'wood';
  if (buildingType === 'stonemason') return 'stone';
  return null;
}

/**
 * Must be called inside a DB transaction.
 * Uses SELECT ... FOR UPDATE to avoid double-production.
 */
export async function applyCatchUpProduction(client, userId) {
  const stateRes = await client.query(
    `SELECT coins, last_tick_at
     FROM player_state
     WHERE user_id = $1
     FOR UPDATE`,
    [userId]
  );

  if (stateRes.rowCount === 0) {
    // user has no state yet (should not happen if register is correct)
    await client.query(
      `INSERT INTO player_state(user_id, coins, last_tick_at) VALUES ($1, 0, now())`,
      [userId]
    );
    return;
  }

  const lastTickAt = new Date(stateRes.rows[0].last_tick_at);
  const now = new Date();
  let elapsedSeconds = Math.floor((now.getTime() - lastTickAt.getTime()) / 1000);
  if (elapsedSeconds <= 0) return;

  elapsedSeconds = Math.min(elapsedSeconds, MAX_ELAPSED_SECONDS);

  // Get buildings
  const bRes = await client.query(
    `SELECT building_type, level FROM buildings WHERE user_id = $1`,
    [userId]
  );

  // Sum production per resource
  const add = { water: 0n, wood: 0n, stone: 0n };

  for (const row of bRes.rows) {
    const bt = row.building_type;
    const lvl = Number(row.level);
    const resType = producedResourceForBuilding(bt);
    if (!resType) continue;

    const produced = ratePerSecond(bt, lvl) * elapsedSeconds;

    // Deterministische Rundung: floor auf ganze Einheiten
    const units = BigInt(Math.floor(produced));
    add[resType] += units;
  }

  // Apply inventory increments
  for (const r of RESOURCES) {
    if (add[r] <= 0n) continue;
    await client.query(
      `INSERT INTO inventory(user_id, resource_type, amount)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, resource_type)
       DO UPDATE SET amount = inventory.amount + EXCLUDED.amount`,
      [userId, r, add[r].toString()]
    );
  }

  // Update last_tick_at
  await client.query(
    `UPDATE player_state SET last_tick_at = now() WHERE user_id = $1`,
    [userId]
  );
}