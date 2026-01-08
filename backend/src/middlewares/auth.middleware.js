/**
 * Authentication Middleware
 * Protects routes by verifying JWT tokens
 * Implements security best practices
 */
const { verifyToken } = require('../utils/jwt');
const User = require('../models/User');

// Track failed login attempts for account lockout
const failedAttempts = new Map();
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_DURATION = 15 * 60 * 1000; // 15 minutes

/**
 * Check if account is locked
 */
const isAccountLocked = (email) => {
  const attempts = failedAttempts.get(email);
  if (!attempts) return false;
  
  if (attempts.count >= MAX_FAILED_ATTEMPTS) {
    const timeSinceLock = Date.now() - attempts.lockedAt;
    if (timeSinceLock < LOCKOUT_DURATION) {
      return true;
    }
    // Reset after lockout period
    failedAttempts.delete(email);
  }
  return false;
};

/**
 * Record failed login attempt
 */
const recordFailedAttempt = (email) => {
  const attempts = failedAttempts.get(email) || { count: 0 };
  attempts.count++;
  if (attempts.count >= MAX_FAILED_ATTEMPTS) {
    attempts.lockedAt = Date.now();
  }
  failedAttempts.set(email, attempts);
};

/**
 * Clear failed attempts on successful login
 */
const clearFailedAttempts = (email) => {
  failedAttempts.delete(email);
};

/**
 * Middleware to protect routes - requires valid JWT token
 */
const protect = async (req, res, next) => {
  try {
    let token;

    // Check for token in Authorization header
    if (req.headers.authorization?.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized, no token provided'
      });
    }

    // Verify token and get user
    const decoded = verifyToken(token);
    
    // Check token expiration
    if (decoded.exp && decoded.exp * 1000 < Date.now()) {
      return res.status(401).json({
        success: false,
        message: 'Token expired, please login again'
      });
    }
    
    const user = await User.findById(decoded.id).select('-password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Attach user to request
    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized, token invalid'
    });
  }
};

/**
 * Optional auth - attaches user if token present, but doesn't require it
 */
const optionalAuth = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization?.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (token) {
      const decoded = verifyToken(token);
      const user = await User.findById(decoded.id).select('-password');
      if (user && user.isActive) {
        req.user = user;
      }
    }
    next();
  } catch (error) {
    // Continue without user if token is invalid
    next();
  }
};

/**
 * Middleware to restrict access to specific roles
 * @param  {...string} roles - Allowed roles
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Not authenticated'
      });
    }
    
    if (!roles.includes(req.user.role)) {
      // Log unauthorized access attempt
      console.log(`[SECURITY] Unauthorized access attempt by user ${req.user.id} to ${req.originalUrl}`);
      return res.status(403).json({
        success: false,
        message: 'Not authorized for this action'
      });
    }
    next();
  };
};

/**
 * Middleware to verify resource ownership
 */
const verifyOwnership = (resourceField = 'user') => {
  return (req, res, next) => {
    // Admin can access all resources
    if (req.user.role === 'admin') {
      return next();
    }
    
    // Check if resource belongs to user
    const resourceUserId = req.resource?.[resourceField]?.toString() || req.resource?.[resourceField];
    if (resourceUserId && resourceUserId !== req.user.id.toString()) {
      console.log(`[SECURITY] Ownership violation by user ${req.user.id}`);
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this resource'
      });
    }
    next();
  };
};

module.exports = { 
  protect, 
  authorize, 
  optionalAuth, 
  verifyOwnership,
  isAccountLocked,
  recordFailedAttempt,
  clearFailedAttempts
};
