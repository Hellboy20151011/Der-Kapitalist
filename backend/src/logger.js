// Simple logger utility for consistent logging
// For production, consider using Winston or Pino

const LOG_LEVELS = {
  ERROR: 'ERROR',
  WARN: 'WARN',
  INFO: 'INFO',
  DEBUG: 'DEBUG'
};

function log(level, message, context = {}) {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    ...context
  };
  
  // In production, this would go to a structured logging service
  console.log(JSON.stringify(logEntry));
}

export const logger = {
  error: (message, context) => log(LOG_LEVELS.ERROR, message, context),
  warn: (message, context) => log(LOG_LEVELS.WARN, message, context),
  info: (message, context) => log(LOG_LEVELS.INFO, message, context),
  debug: (message, context) => log(LOG_LEVELS.DEBUG, message, context)
};
