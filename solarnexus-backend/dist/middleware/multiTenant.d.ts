import { Request, Response, NextFunction } from 'express';
export interface MultiTenantRequest extends Request {
    organization?: {
        id: string;
        name: string;
        slug: string;
        settings?: any;
    };
}
export declare const multiTenantMiddleware: (req: MultiTenantRequest, res: Response, next: NextFunction) => Promise<void>;
export declare const requireOrganization: (req: MultiTenantRequest, res: Response, next: NextFunction) => Response<any, Record<string, any>> | undefined;
//# sourceMappingURL=multiTenant.d.ts.map