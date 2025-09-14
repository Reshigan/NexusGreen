import { Request, Response, NextFunction } from 'express';
export interface RequestWithId extends Request {
    requestId?: string;
}
export declare const requestLogger: (req: RequestWithId, res: Response, next: NextFunction) => void;
//# sourceMappingURL=requestLogger.d.ts.map