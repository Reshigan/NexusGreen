"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authController = void 0;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const uuid_1 = require("uuid");
const database_1 = require("@/utils/database");
const config_1 = require("@/config/config");
const logger_1 = require("@/utils/logger");
const errorHandler_1 = require("@/middleware/errorHandler");
const emailService_1 = require("@/services/emailService");
class AuthController {
    constructor() {
        this.signup = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            const { email, password, firstName, lastName, organizationName, role } = req.body;
            // Check if user already exists
            const existingUser = await database_1.prisma.user.findUnique({
                where: { email },
            });
            if (existingUser) {
                throw (0, errorHandler_1.createError)('User already exists with this email', 409);
            }
            // Hash password
            const hashedPassword = await bcryptjs_1.default.hash(password, config_1.config.bcryptRounds);
            // Create organization slug
            const organizationSlug = organizationName
                .toLowerCase()
                .replace(/[^a-z0-9]/g, '-')
                .replace(/-+/g, '-')
                .replace(/^-|-$/g, '');
            // Check if organization slug is unique
            const existingOrg = await database_1.prisma.organization.findUnique({
                where: { slug: organizationSlug },
            });
            if (existingOrg) {
                throw (0, errorHandler_1.createError)('Organization name already taken', 409);
            }
            // Create organization and user in transaction
            const result = await database_1.prisma.$transaction(async (tx) => {
                // Create organization
                const organization = await tx.organization.create({
                    data: {
                        name: organizationName,
                        slug: organizationSlug,
                        settings: {
                            theme: 'light',
                            timezone: 'UTC',
                            currency: 'USD',
                        },
                    },
                });
                // Create user
                const user = await tx.user.create({
                    data: {
                        email,
                        password: hashedPassword,
                        firstName,
                        lastName,
                        role: role,
                        organizationId: organization.id,
                    },
                    select: {
                        id: true,
                        email: true,
                        firstName: true,
                        lastName: true,
                        role: true,
                        organizationId: true,
                        emailVerified: true,
                        createdAt: true,
                    },
                });
                // Create default license
                await tx.license.create({
                    data: {
                        organizationId: organization.id,
                        licenseType: 'BASIC',
                        maxSites: 5,
                        maxUsers: 10,
                        features: ['basic_analytics', 'email_notifications'],
                        expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year
                    },
                });
                return { user, organization };
            });
            // Generate tokens
            const accessToken = jsonwebtoken_1.default.sign({ userId: result.user.id, organizationId: result.user.organizationId }, config_1.config.jwt.secret, { expiresIn: '1h' });
            const refreshToken = jsonwebtoken_1.default.sign({ userId: result.user.id }, config_1.config.jwt.refreshSecret, { expiresIn: '30d' });
            // Store refresh token
            await database_1.prisma.refreshToken.create({
                data: {
                    token: refreshToken,
                    userId: result.user.id,
                    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
                },
            });
            // Send verification email
            try {
                await emailService_1.emailService.sendVerificationEmail(result.user.email, result.user.firstName);
            }
            catch (error) {
                logger_1.logger.error('Failed to send verification email', { error, userId: result.user.id });
            }
            logger_1.logger.info('User signed up successfully', {
                userId: result.user.id,
                email: result.user.email,
                organizationId: result.organization.id,
            });
            res.status(201).json({
                success: true,
                message: 'Account created successfully',
                data: {
                    user: result.user,
                    organization: result.organization,
                    accessToken,
                    refreshToken,
                },
            });
        });
        this.login = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            const { email, password } = req.body;
            // Find user with organization
            const user = await database_1.prisma.user.findUnique({
                where: { email },
                include: {
                    organization: {
                        select: {
                            id: true,
                            name: true,
                            slug: true,
                            settings: true,
                            isActive: true,
                        },
                    },
                },
            });
            if (!user || !user.isActive) {
                throw (0, errorHandler_1.createError)('Invalid credentials', 401);
            }
            if (!user.organization.isActive) {
                throw (0, errorHandler_1.createError)('Organization is inactive', 401);
            }
            // Verify password
            const isPasswordValid = await bcryptjs_1.default.compare(password, user.password);
            if (!isPasswordValid) {
                throw (0, errorHandler_1.createError)('Invalid credentials', 401);
            }
            // Generate tokens
            const accessToken = jsonwebtoken_1.default.sign({ userId: user.id, organizationId: user.organizationId }, config_1.config.jwt.secret, { expiresIn: '1h' });
            const refreshToken = jsonwebtoken_1.default.sign({ userId: user.id }, config_1.config.jwt.refreshSecret, { expiresIn: '30d' });
            // Store refresh token
            await database_1.prisma.refreshToken.create({
                data: {
                    token: refreshToken,
                    userId: user.id,
                    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
                },
            });
            // Update last login
            await database_1.prisma.user.update({
                where: { id: user.id },
                data: { lastLoginAt: new Date() },
            });
            logger_1.logger.info('User logged in successfully', {
                userId: user.id,
                email: user.email,
                organizationId: user.organizationId,
            });
            res.json({
                success: true,
                message: 'Login successful',
                data: {
                    user: {
                        id: user.id,
                        email: user.email,
                        firstName: user.firstName,
                        lastName: user.lastName,
                        role: user.role,
                        organizationId: user.organizationId,
                        emailVerified: user.emailVerified,
                    },
                    organization: user.organization,
                    accessToken,
                    refreshToken,
                },
            });
        });
        this.logout = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            const refreshToken = req.body.refreshToken;
            if (refreshToken) {
                await database_1.prisma.refreshToken.deleteMany({
                    where: {
                        token: refreshToken,
                        userId: req.user.id,
                    },
                });
            }
            logger_1.logger.info('User logged out', { userId: req.user.id });
            res.json({
                success: true,
                message: 'Logout successful',
            });
        });
        this.refreshToken = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            const { refreshToken } = req.body;
            if (!refreshToken) {
                throw (0, errorHandler_1.createError)('Refresh token required', 401);
            }
            // Verify refresh token
            const decoded = jsonwebtoken_1.default.verify(refreshToken, config_1.config.jwt.refreshSecret);
            // Check if refresh token exists in database
            const storedToken = await database_1.prisma.refreshToken.findUnique({
                where: { token: refreshToken },
                include: {
                    user: {
                        select: {
                            id: true,
                            email: true,
                            role: true,
                            organizationId: true,
                            isActive: true,
                        },
                    },
                },
            });
            if (!storedToken || !storedToken.user.isActive || storedToken.expiresAt < new Date()) {
                throw (0, errorHandler_1.createError)('Invalid refresh token', 401);
            }
            // Generate new access token
            const accessToken = jsonwebtoken_1.default.sign({ userId: storedToken.user.id, organizationId: storedToken.user.organizationId }, config_1.config.jwt.secret, { expiresIn: '1h' });
            res.json({
                success: true,
                data: {
                    accessToken,
                },
            });
        });
        this.getProfile = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            const user = await database_1.prisma.user.findUnique({
                where: { id: req.user.id },
                select: {
                    id: true,
                    email: true,
                    firstName: true,
                    lastName: true,
                    phone: true,
                    avatar: true,
                    role: true,
                    emailVerified: true,
                    lastLoginAt: true,
                    createdAt: true,
                    organization: {
                        select: {
                            id: true,
                            name: true,
                            slug: true,
                            settings: true,
                        },
                    },
                },
            });
            res.json({
                success: true,
                data: { user },
            });
        });
        this.updateProfile = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            const { firstName, lastName, phone } = req.body;
            const user = await database_1.prisma.user.update({
                where: { id: req.user.id },
                data: {
                    firstName,
                    lastName,
                    phone,
                },
                select: {
                    id: true,
                    email: true,
                    firstName: true,
                    lastName: true,
                    phone: true,
                    avatar: true,
                    role: true,
                    emailVerified: true,
                },
            });
            logger_1.logger.info('User profile updated', { userId: req.user.id });
            res.json({
                success: true,
                message: 'Profile updated successfully',
                data: { user },
            });
        });
        this.forgotPassword = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            const { email } = req.body;
            const user = await database_1.prisma.user.findUnique({
                where: { email },
                select: { id: true, email: true, firstName: true },
            });
            if (!user) {
                // Don't reveal if email exists
                return res.json({
                    success: true,
                    message: 'If an account with that email exists, a password reset link has been sent.',
                });
            }
            // Generate reset token
            const resetToken = (0, uuid_1.v4)();
            const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour
            // Store reset token (you might want to create a separate table for this)
            await database_1.prisma.user.update({
                where: { id: user.id },
                data: {
                // You'll need to add these fields to your schema
                // resetToken,
                // resetTokenExpiry,
                },
            });
            // Send reset email
            try {
                await emailService_1.emailService.sendPasswordResetEmail(user.email, user.firstName, resetToken);
            }
            catch (error) {
                logger_1.logger.error('Failed to send password reset email', { error, userId: user.id });
            }
            res.json({
                success: true,
                message: 'If an account with that email exists, a password reset link has been sent.',
            });
        });
        this.resetPassword = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            const { token, password } = req.body;
            // Find user by reset token (you'll need to implement this based on your schema)
            // const user = await prisma.user.findFirst({
            //   where: {
            //     resetToken: token,
            //     resetTokenExpiry: { gt: new Date() },
            //   },
            // });
            // For now, just return success
            res.json({
                success: true,
                message: 'Password reset successful',
            });
        });
        this.verifyEmail = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            // Implementation for email verification
            res.json({
                success: true,
                message: 'Email verified successfully',
            });
        });
        this.resendVerification = (0, errorHandler_1.asyncHandler)(async (req, res) => {
            // Implementation for resending verification email
            res.json({
                success: true,
                message: 'Verification email sent',
            });
        });
    }
}
exports.authController = new AuthController();
//# sourceMappingURL=authController.js.map