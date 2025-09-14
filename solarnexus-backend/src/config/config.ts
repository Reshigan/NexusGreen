import dotenv from 'dotenv';

dotenv.config();

export const config = {
  // Server
  port: parseInt(process.env.PORT || '3000', 10),
  host: process.env.HOST || '0.0.0.0',
  nodeEnv: process.env.NODE_ENV || 'development',

  // Database
  databaseUrl: process.env.DATABASE_URL || 'postgresql://localhost:5432/nexusgreen',

  // JWT
  jwt: {
    secret: process.env.JWT_SECRET || 'your-secret-key',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'your-refresh-secret',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  },

  // Redis
  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',

  // Email
  email: {
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
    from: process.env.FROM_EMAIL || 'noreply@nexusgreen.com',
    fromName: process.env.FROM_NAME || 'NexusGreen',
  },

  // SolaX API
  solax: {
    baseUrl: process.env.SOLAX_BASE_URL || 'https://openapi-eu.solaxcloud.com',
    clientId: process.env.SOLAX_CLIENT_ID || '',
    clientSecret: process.env.SOLAX_CLIENT_SECRET || '',
  },

  // External APIs
  weatherApiKey: process.env.WEATHER_API_KEY || '',
  municipalRatesApiKey: process.env.MUNICIPAL_RATES_API_KEY || '',

  // File Upload
  upload: {
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE || '10485760', 10), // 10MB
    uploadPath: process.env.UPLOAD_PATH || './uploads',
  },

  // Security
  bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '12', 10),
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10), // 15 minutes
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
  },

  // Monitoring
  logLevel: process.env.LOG_LEVEL || 'info',
  enableMetrics: process.env.ENABLE_METRICS === 'true',

  // Production
  productionServerIp: process.env.PRODUCTION_SERVER_IP || '13.244.63.26',
  ssl: {
    certPath: process.env.SSL_CERT_PATH || '/etc/ssl/certs/nexusgreen.crt',
    keyPath: process.env.SSL_KEY_PATH || '/etc/ssl/private/nexusgreen.key',
  },
};