const RESOURCES = ['water', 'wood', 'stone', 'sand', 'limestone', 'cement', 'concrete', 'stone_blocks', 'wood_planks'];
const BUILDINGS = ['well', 'lumberjack', 'sandgrube', 'kalktagebau', 'steinfabrik', 'saegewerk', 'zementwerk', 'betonfabrik'];

// Startwerte: Produktion pro Minute bei Level 1
const BASE_RATE_PER_MIN = {
  well: 30,
  lumberjack: 15,
  sandgrube: 10,
  kalktagebau: 8,
  steinfabrik: 6,
  saegewerk: 12,
  zementwerk: 5,
  betonfabrik: 4
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
  if (buildingType === 'sandgrube') return 'sand';
  if (buildingType === 'kalktagebau') return 'limestone';
  if (buildingType === 'steinfabrik') return 'stone_blocks';
  if (buildingType === 'saegewerk') return 'wood_planks';
  if (buildingType === 'zementwerk') return 'cement';
  if (buildingType === 'betonfabrik') return 'concrete';
  return null;
}

/**
 * IDLE PRODUCTION DISABLED
 * 
 * This service previously provided automatic resource production based on elapsed time.
 * Production is now manual only - players must start production via the UI slider system.
 * 
 * The functions and constants above are kept for potential future use or reference,
 * but are not currently used in the production system.
 */