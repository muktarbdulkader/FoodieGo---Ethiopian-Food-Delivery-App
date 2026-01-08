/**
 * Error Handling Middleware
 * Centralized error handling with security considerations
 */

/**
 * Global error handler middleware
 * Hides sensitive error details in production
 */
const errorHandler = (err, req, res, next) => {
  // Log error for debugging (but not sensitive data)
  const errorLog = {
    timestamp: new Date().toISOString(),
    method: req.method,
    url: req.originalUrl,
    error: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  };
  console.error('[ERROR]', JSON.stringify(errorLog));

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const messages = Object.values(err.errors).map(e => e.message);
    return res.status(400).json({
      success: false,
      message: messages.join(', ')
    });
  }

  // Mongoose duplicate key error
  if (err.code === 11000) {
    // Don't reveal which field is duplicate in production
    const message = process.env.NODE_ENV === 'development' 
      ? `Duplicate field: ${Object.keys(err.keyPattern).join(', ')}`
      : 'A record with this information already exists';
    return res.status(400).json({
      success: false,
      message
    });
  }

  // Mongoose CastError (invalid ObjectId)
  if (err.name === 'CastError') {
    return res.status(400).json({
      success: false,
      message: 'Invalid ID format'
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Invalid token'
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Token expired, please login again'
    });
  }

  // Don't leak error details in production
  const statusCode = err.statusCode || 500;
  const message = statusCode === 500 && process.env.NODE_ENV === 'production'
    ? 'An unexpected error occurred'
    : err.message || 'Server Error';

  res.status(statusCode).json({
    success: false,
    message,
    // Only include stack trace in development
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

/**
 * 404 Not Found handler
 */
const notFound = (req, res, next) => {
  // Log 404 for potential security monitoring
  console.log(`[404] ${req.method} ${req.originalUrl} from ${req.ip}`);
  
  res.status(404).json({
    success: false,
    message: 'Resource not found'
  });
};

module.exports = { errorHandler, notFound };
