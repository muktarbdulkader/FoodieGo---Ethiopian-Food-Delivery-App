/**
 * Express Application Setup
 * Configures middleware, security, and routes
 */
const express = require('express');
const cors = require('cors');
const routes = require('./routes');
const { errorHandler, notFound } = require('./middlewares/error.middleware');

const app = express();

// ===================
// SECURITY MIDDLEWARE
// ===================

// Rate limiting - prevent brute force attacks
const rateLimit = {};
const RATE_LIMIT_WINDOW = 60 * 1000; // 1 minute
const MAX_REQUESTS = 100; // max requests per window

const rateLimiter = (req, res, next) => {
  const ip = req.ip || req.connection.remoteAddress;
  const now = Date.now();
  
  if (!rateLimit[ip]) {
    rateLimit[ip] = { count: 1, startTime: now };
  } else if (now - rateLimit[ip].startTime > RATE_LIMIT_WINDOW) {
    rateLimit[ip] = { count: 1, startTime: now };
  } else {
    rateLimit[ip].count++;
    if (rateLimit[ip].count > MAX_REQUESTS) {
      return res.status(429).json({
        success: false,
        message: 'Too many requests. Please try again later.'
      });
    }
  }
  next();
};

// Security headers
const securityHeaders = (req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.removeHeader('X-Powered-By');
  next();
};

// Request logging for audit trail (non-repudiation)
const auditLogger = (req, res, next) => {
  const timestamp = new Date().toISOString();
  const method = req.method;
  const url = req.originalUrl;
  const ip = req.ip || req.connection.remoteAddress;
  const userId = req.user?.id || 'anonymous';
  
  // Log to console (in production, use proper logging service)
  if (process.env.NODE_ENV !== 'test') {
    console.log(`[AUDIT] ${timestamp} | ${method} ${url} | IP: ${ip} | User: ${userId}`);
  }
  
  // Store original end function
  const originalEnd = res.end;
  res.end = function(...args) {
    if (process.env.NODE_ENV !== 'test') {
      console.log(`[AUDIT] ${timestamp} | ${method} ${url} | Status: ${res.statusCode}`);
    }
    originalEnd.apply(res, args);
  };
  
  next();
};

// Input sanitization
const sanitizeInput = (req, res, next) => {
  const sanitize = (obj) => {
    if (typeof obj === 'string') {
      // Remove potential XSS characters
      return obj.replace(/<[^>]*>/g, '').trim();
    }
    if (typeof obj === 'object' && obj !== null) {
      for (const key in obj) {
        // Prevent NoSQL injection
        if (key.startsWith('$')) {
          delete obj[key];
        } else {
          obj[key] = sanitize(obj[key]);
        }
      }
    }
    return obj;
  };
  
  if (req.body) req.body = sanitize(req.body);
  if (req.query) req.query = sanitize(req.query);
  if (req.params) req.params = sanitize(req.params);
  
  next();
};

// Apply security middleware
app.use(rateLimiter);
app.use(securityHeaders);
app.use(auditLogger);

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

// Body parsing with size limits (prevent DoS)
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Input sanitization
app.use(sanitizeInput);

// API Routes
app.use('/api', routes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// API health check endpoint (for Render)
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling
app.use(notFound);
app.use(errorHandler);

module.exports = app;
