import { Router } from 'express';
import { body } from 'express-validator';
import { authController } from '@/controllers/authController';
import { authRateLimiter } from '@/middleware/rateLimiter';
import { authenticate } from '@/middleware/auth';
import { validate } from '@/middleware/validation';

const router = Router();

// Validation rules
const signupValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
  body('firstName').trim().isLength({ min: 1, max: 50 }),
  body('lastName').trim().isLength({ min: 1, max: 50 }),
  body('organizationName').trim().isLength({ min: 1, max: 100 }),
  body('role').isIn(['CUSTOMER', 'FUNDER', 'OM_PROVIDER']),
];

const loginValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
];

const forgotPasswordValidation = [
  body('email').isEmail().normalizeEmail(),
];

const resetPasswordValidation = [
  body('token').notEmpty(),
  body('password').isLength({ min: 8 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
];

// Routes
router.post('/signup', authRateLimiter, signupValidation, validate, authController.signup);
router.post('/login', authRateLimiter, loginValidation, validate, authController.login);
router.post('/logout', authenticate, authController.logout);
router.post('/refresh', authController.refreshToken);
router.get('/me', authenticate, authController.getProfile);
router.put('/profile', authenticate, authController.updateProfile);
router.post('/forgot-password', authRateLimiter, forgotPasswordValidation, validate, authController.forgotPassword);
router.post('/reset-password', authRateLimiter, resetPasswordValidation, validate, authController.resetPassword);
router.post('/verify-email', authController.verifyEmail);
router.post('/resend-verification', authRateLimiter, authController.resendVerification);

export default router;