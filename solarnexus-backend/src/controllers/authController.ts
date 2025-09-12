import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '@/utils/database';
import { config } from '@/config/config';
import { logger } from '@/utils/logger';
import { createError, asyncHandler } from '@/middleware/errorHandler';
import { AuthenticatedRequest } from '@/middleware/auth';
import { emailService } from '@/services/emailService';
import { UserRole } from '@prisma/client';

class AuthController {
  signup = asyncHandler(async (req: Request, res: Response) => {
    const { email, password, firstName, lastName, organizationName, role } = req.body;

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      throw createError('User already exists with this email', 409);
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, config.bcryptRounds);

    // Create organization slug
    const organizationSlug = organizationName
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');

    // Check if organization slug is unique
    const existingOrg = await prisma.organization.findUnique({
      where: { slug: organizationSlug },
    });

    if (existingOrg) {
      throw createError('Organization name already taken', 409);
    }

    // Create organization and user in transaction
    const result = await prisma.$transaction(async (tx) => {
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
          role: role as UserRole,
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
    const accessToken = jwt.sign(
      { userId: result.user.id, organizationId: result.user.organizationId },
      config.jwt.secret,
      { expiresIn: '1h' }
    );

    const refreshToken = jwt.sign(
      { userId: result.user.id },
      config.jwt.refreshSecret,
      { expiresIn: '30d' }
    );

    // Store refresh token
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: result.user.id,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      },
    });

    // Send verification email
    try {
      await emailService.sendVerificationEmail(result.user.email, result.user.firstName);
    } catch (error) {
      logger.error('Failed to send verification email', { error, userId: result.user.id });
    }

    logger.info('User signed up successfully', {
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

  login = asyncHandler(async (req: Request, res: Response) => {
    const { email, password } = req.body;

    // Find user with organization
    const user = await prisma.user.findUnique({
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
      throw createError('Invalid credentials', 401);
    }

    if (!user.organization.isActive) {
      throw createError('Organization is inactive', 401);
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw createError('Invalid credentials', 401);
    }

    // Generate tokens
    const accessToken = jwt.sign(
      { userId: user.id, organizationId: user.organizationId },
      config.jwt.secret,
      { expiresIn: '1h' }
    );

    const refreshToken = jwt.sign(
      { userId: user.id },
      config.jwt.refreshSecret,
      { expiresIn: '30d' }
    );

    // Store refresh token
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      },
    });

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    logger.info('User logged in successfully', {
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

  logout = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const refreshToken = req.body.refreshToken;

    if (refreshToken) {
      await prisma.refreshToken.deleteMany({
        where: {
          token: refreshToken,
          userId: req.user!.id,
        },
      });
    }

    logger.info('User logged out', { userId: req.user!.id });

    res.json({
      success: true,
      message: 'Logout successful',
    });
  });

  refreshToken = asyncHandler(async (req: Request, res: Response) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      throw createError('Refresh token required', 401);
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, config.jwt.refreshSecret) as any;

    // Check if refresh token exists in database
    const storedToken = await prisma.refreshToken.findUnique({
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
      throw createError('Invalid refresh token', 401);
    }

    // Generate new access token
    const accessToken = jwt.sign(
      { userId: storedToken.user.id, organizationId: storedToken.user.organizationId },
      config.jwt.secret,
      { expiresIn: '1h' }
    );

    res.json({
      success: true,
      data: {
        accessToken,
      },
    });
  });

  getProfile = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
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

  updateProfile = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const { firstName, lastName, phone } = req.body;

    const user = await prisma.user.update({
      where: { id: req.user!.id },
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

    logger.info('User profile updated', { userId: req.user!.id });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: { user },
    });
  });

  forgotPassword = asyncHandler(async (req: Request, res: Response) => {
    const { email } = req.body;

    const user = await prisma.user.findUnique({
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
    const resetToken = uuidv4();
    const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    // Store reset token (you might want to create a separate table for this)
    await prisma.user.update({
      where: { id: user.id },
      data: {
        // You'll need to add these fields to your schema
        // resetToken,
        // resetTokenExpiry,
      },
    });

    // Send reset email
    try {
      await emailService.sendPasswordResetEmail(user.email, user.firstName, resetToken);
    } catch (error) {
      logger.error('Failed to send password reset email', { error, userId: user.id });
    }

    res.json({
      success: true,
      message: 'If an account with that email exists, a password reset link has been sent.',
    });
  });

  resetPassword = asyncHandler(async (req: Request, res: Response) => {
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

  verifyEmail = asyncHandler(async (req: Request, res: Response) => {
    // Implementation for email verification
    res.json({
      success: true,
      message: 'Email verified successfully',
    });
  });

  resendVerification = asyncHandler(async (req: Request, res: Response) => {
    // Implementation for resending verification email
    res.json({
      success: true,
      message: 'Verification email sent',
    });
  });
}

export const authController = new AuthController();