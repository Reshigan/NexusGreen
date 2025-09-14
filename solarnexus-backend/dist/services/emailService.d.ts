declare class EmailService {
    private transporter;
    constructor();
    sendEmail(to: string, subject: string, html: string, text?: string): Promise<any>;
    sendVerificationEmail(email: string, firstName: string): Promise<any>;
    sendPasswordResetEmail(email: string, firstName: string, resetToken: string): Promise<any>;
    sendAlertNotification(email: string, firstName: string, alertTitle: string, alertDescription: string, siteName: string): Promise<any>;
}
export declare const emailService: EmailService;
export {};
//# sourceMappingURL=emailService.d.ts.map