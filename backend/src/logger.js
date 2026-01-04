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
  
  const output = JSON.stringify(logEntry);
  
  // Route to appropriate console stream based on log level
  if (level === LOG_LEVELS.ERROR) {
    console.error(output);
  } else if (level === LOG_LEVELS.WARN) {
    console.warn(output);
  } else {
    console.log(output);
  }
}

export const logger = {
  error: (message, context) => log(LOG_LEVELS.ERROR, message, context),
  warn: (message, context) => log(LOG_LEVELS.WARN, message, context),
  info: (message, context) => log(LOG_LEVELS.INFO, message, context),
  debug: (message, context) => log(LOG_LEVELS.DEBUG, message, context)
};
