"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.emailService = void 0;
const nodemailer_1 = __importDefault(require("nodemailer"));
const config_1 = require("@/config/config");
const logger_1 = require("@/utils/logger");
class EmailService {
    constructor() {
        this.transporter = nodemailer_1.default.createTransport({
            host: config_1.config.email.host,
            port: config_1.config.email.port,
            secure: false, // true for 465, false for other ports
            auth: {
                user: config_1.config.email.user,
                pass: config_1.config.email.pass,
            },
        });
    }
    async sendEmail(to, subject, html, text) {
        try {
            const info = await this.transporter.sendMail({
                from: `${config_1.config.email.fromName} <${config_1.config.email.from}>`,
                to,
                subject,
                text,
                html,
            });
            logger_1.logger.info('Email sent successfully', {
                messageId: info.messageId,
                to,
                subject,
            });
            return info;
        }
        catch (error) {
            logger_1.logger.error('Failed to send email', { error, to, subject });
            throw error;
        }
    }
    async sendVerificationEmail(email, firstName) {
        const subject = 'Welcome to SolarNexus - Verify Your Email';
        const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Welcome to SolarNexus</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #0891b2, #f97316); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }
            .button { display: inline-block; background: #0891b2; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #6b7280; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Welcome to SolarNexus!</h1>
              <p>Smart Solar Analytics Platform</p>
            </div>
            <div class="content">
              <h2>Hello ${firstName},</h2>
              <p>Thank you for joining SolarNexus! We're excited to help you optimize your solar energy management.</p>
              <p>To get started, please verify your email address by clicking the button below:</p>
              <a href="#" class="button">Verify Email Address</a>
              <p>If you didn't create this account, please ignore this email.</p>
              <p>Best regards,<br>The SolarNexus Team</p>
            </div>
            <div class="footer">
              <p>© 2024 SolarNexus. All rights reserved.</p>
            </div>
          </div>
        </body>
      </html>
    `;
        return this.sendEmail(email, subject, html);
    }
    async sendPasswordResetEmail(email, firstName, resetToken) {
        const subject = 'Reset Your SolarNexus Password';
        const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
        const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Reset Your Password</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #0891b2, #f97316); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }
            .button { display: inline-block; background: #0891b2; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #6b7280; font-size: 14px; }
            .warning { background: #fef3c7; border: 1px solid #f59e0b; padding: 15px; border-radius: 6px; margin: 20px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Password Reset Request</h1>
            </div>
            <div class="content">
              <h2>Hello ${firstName},</h2>
              <p>We received a request to reset your SolarNexus password.</p>
              <p>Click the button below to reset your password:</p>
              <a href="${resetUrl}" class="button">Reset Password</a>
              <div class="warning">
                <strong>Security Notice:</strong> This link will expire in 1 hour. If you didn't request this password reset, please ignore this email.
              </div>
              <p>Best regards,<br>The SolarNexus Team</p>
            </div>
            <div class="footer">
              <p>© 2024 SolarNexus. All rights reserved.</p>
            </div>
          </div>
        </body>
      </html>
    `;
        return this.sendEmail(email, subject, html);
    }
    async sendAlertNotification(email, firstName, alertTitle, alertDescription, siteName) {
        const subject = `SolarNexus Alert: ${alertTitle}`;
        const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>SolarNexus Alert</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #ef4444; color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }
            .alert-box { background: #fef2f2; border: 1px solid #ef4444; padding: 20px; border-radius: 6px; margin: 20px 0; }
            .button { display: inline-block; background: #0891b2; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #6b7280; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>⚠️ System Alert</h1>
            </div>
            <div class="content">
              <h2>Hello ${firstName},</h2>
              <p>We've detected an issue with your solar system at <strong>${siteName}</strong>.</p>
              <div class="alert-box">
                <h3>${alertTitle}</h3>
                <p>${alertDescription}</p>
              </div>
              <p>Please review this alert in your SolarNexus dashboard:</p>
              <a href="#" class="button">View Dashboard</a>
              <p>Best regards,<br>The SolarNexus Team</p>
            </div>
            <div class="footer">
              <p>© 2024 SolarNexus. All rights reserved.</p>
            </div>
          </div>
        </body>
      </html>
    `;
        return this.sendEmail(email, subject, html);
    }
}
exports.emailService = new EmailService();
//# sourceMappingURL=emailService.js.map