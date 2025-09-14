"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const express_validator_1 = require("express-validator");
const authController_1 = require("@/controllers/authController");
const rateLimiter_1 = require("@/middleware/rateLimiter");
const auth_1 = require("@/middleware/auth");
const validation_1 = require("@/middleware/validation");
const router = (0, express_1.Router)();
// Validation rules
const signupValidation = [
    (0, express_validator_1.body)('email').isEmail().normalizeEmail(),
    (0, express_validator_1.body)('password').isLength({ min: 8 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
    (0, express_validator_1.body)('firstName').trim().isLength({ min: 1, max: 50 }),
    (0, express_validator_1.body)('lastName').trim().isLength({ min: 1, max: 50 }),
    (0, express_validator_1.body)('organizationName').trim().isLength({ min: 1, max: 100 }),
    (0, express_validator_1.body)('role').isIn(['CUSTOMER', 'FUNDER', 'OM_PROVIDER']),
];
const loginValidation = [
    (0, express_validator_1.body)('email').isEmail().normalizeEmail(),
    (0, express_validator_1.body)('password').notEmpty(),
];
const forgotPasswordValidation = [
    (0, express_validator_1.body)('email').isEmail().normalizeEmail(),
];
const resetPasswordValidation = [
    (0, express_validator_1.body)('token').notEmpty(),
    (0, express_validator_1.body)('password').isLength({ min: 8 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
];
// Routes
router.post('/signup', rateLimiter_1.authRateLimiter, signupValidation, validation_1.validate, authController_1.authController.signup);
router.post('/login', rateLimiter_1.authRateLimiter, loginValidation, validation_1.validate, authController_1.authController.login);
router.post('/logout', auth_1.authenticate, authController_1.authController.logout);
router.post('/refresh', authController_1.authController.refreshToken);
router.get('/me', auth_1.authenticate, authController_1.authController.getProfile);
router.put('/profile', auth_1.authenticate, authController_1.authController.updateProfile);
router.post('/forgot-password', rateLimiter_1.authRateLimiter, forgotPasswordValidation, validation_1.validate, authController_1.authController.forgotPassword);
router.post('/reset-password', rateLimiter_1.authRateLimiter, resetPasswordValidation, validation_1.validate, authController_1.authController.resetPassword);
router.post('/verify-email', authController_1.authController.verifyEmail);
router.post('/resend-verification', rateLimiter_1.authRateLimiter, authController_1.authController.resendVerification);
exports.default = router;
//# sourceMappingURL=auth.js.map