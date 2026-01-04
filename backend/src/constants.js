// Game Configuration Constants
// Centralized configuration for game mechanics

// Production costs (coins per unit)
export const PRODUCTION_COSTS = {
  well: 1n,
  lumberjack: 2n,
  sandgrube: 3n,
  kalktagebau: 1n,
  steinfabrik: 2n,
  saegewerk: 1n,
  zementwerk: 2n,
  betonfabrik: 2n
};

// Production time (seconds per unit)
export const PRODUCTION_TIME = {
  well: 3,
  lumberjack: 5,
  sandgrube: 7,
  kalktagebau: 6,
  steinfabrik: 8,
  saegewerk: 7,
  zementwerk: 10,
  betonfabrik: 12
};

// Resource output mapping
export const BUILDING_RESOURCES = {
  well: 'water',
  lumberjack: 'wood',
  sandgrube: 'stone',
  kalktagebau: 'limestone',
  steinfabrik: 'stone_blocks',
  saegewerk: 'wood_planks',
  zementwerk: 'cement',
  betonfabrik: 'concrete'
};

// Sell prices (multiplier of base value)
export const SELL_PRICES = {
  water: 1.2,
  wood: 1.3,
  stone: 1.4,
  sand: 1.5,
  limestone: 1.6,
  cement: 2.0,
  concrete: 2.5,
  stone_blocks: 2.2,
  wood_planks: 1.8
};

// Building upgrade costs (formula: base * multiplier^(level-1))
export const UPGRADE_COST_BASE = 100;
export const UPGRADE_COST_MULTIPLIER = 1.6;

// Market configuration
export const MARKET_CONFIG = {
  feePercent: 7,
  maxActiveListingsPerUser: 10,
  listingExpirationHours: 24
};

// Production growth rate (for idle production calculations, currently disabled)
export const PRODUCTION_GROWTH_RATE = 1.15;

// Maximum offline production cap (currently not used as idle production is disabled)
export const MAX_OFFLINE_PRODUCTION_HOURS = 8;

// Resource types
export const RESOURCE_TYPES = ['water', 'wood', 'stone', 'sand', 'limestone', 'cement', 'concrete', 'stone_blocks', 'wood_planks'];

// Building types
export const BUILDING_TYPES = ['well', 'lumberjack', 'sandgrube', 'kalktagebau', 'steinfabrik', 'saegewerk', 'zementwerk', 'betonfabrik'];

// Starting resources for new players
export const STARTING_COINS = 100n;
export const STARTING_BUILDINGS = ['well', 'lumberjack', 'sandgrube'];

// Building construction costs
export const BUILD_COSTS = {
  lumberjack: { coins: 10n, wood: 10n, stone: 0n },
  sandgrube: { coins: 10n, wood: 10n, stone: 0n },
  well: { coins: 10n, wood: 10n, stone: 20n },
  kalktagebau: { coins: 50n, wood: 20n, stone: 30n },
  steinfabrik: { coins: 100n, wood: 30n, sand: 50n },
  saegewerk: { coins: 75n, wood: 40n, stone: 20n },
  zementwerk: { coins: 150n, wood: 30n, sand: 40n, limestone: 40n },
  betonfabrik: { coins: 200n, wood: 40n, cement: 30n, sand: 60n }
};

// Input validation limits
export const VALIDATION_LIMITS = {
  maxQuantity: 1_000_000,
  maxPrice: 1_000_000_000,
  maxProductionQuantity: 1000
};
