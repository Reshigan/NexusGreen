import { Request, Response, NextFunction } from 'express';
import { UserRole } from '@prisma/client';
import type { AuthenticatedRequest } from '@/types/express';
export type { AuthenticatedRequest };
export declare const authenticate: (req: Request, res: Response, next: NextFunction) => Promise<void>;
export declare const authorize: (...roles: UserRole[]) => (req: Request, res: Response, next: NextFunction) => void;
export declare const requireSuperAdmin: (req: Request, res: Response, next: NextFunction) => void;
export declare const requireCustomer: (req: Request, res: Response, next: NextFunction) => void;
export declare const requireFunder: (req: Request, res: Response, next: NextFunction) => void;
export declare const requireOMProvider: (req: Request, res: Response, next: NextFunction) => void;
export declare const requireAnyRole: (req: Request, res: Response, next: NextFunction) => void;
export declare const authenticateToken: (req: Request, res: Response, next: NextFunction) => Promise<void>;
export declare const requireRole: (req: Request, res: Response, next: NextFunction) => void;
//# sourceMappingURL=auth.d.ts.map