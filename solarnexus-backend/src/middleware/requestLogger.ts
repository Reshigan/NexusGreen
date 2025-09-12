import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '@/utils/logger';

export interface RequestWithId extends Request {
  requestId?: string;
}

export const requestLogger = (
  req: RequestWithId,
  res: Response,
  next: NextFunction
) => {
  // Generate unique request ID
  req.requestId = uuidv4();
  
  // Add request ID to response headers
  res.setHeader('X-Request-ID', req.requestId);
  
  // Log request start
  const startTime = Date.now();
  
  logger.info('Request started', {
    requestId: req.requestId,
    method: req.method,
    url: req.url,
    userAgent: req.get('User-Agent'),
    ip: req.ip,
    organizationId: req.headers['x-organization-id'],
  });

  // Override res.json to log response
  const originalJson = res.json;
  res.json = function(body: any) {
    const duration = Date.now() - startTime;
    
    logger.info('Request completed', {
      requestId: req.requestId,
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      responseSize: JSON.stringify(body).length,
    });
    
    return originalJson.call(this, body);
  };

  next();
};