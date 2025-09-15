import { Router, Request, Response } from 'express';
import { authenticateToken, requireSuperAdmin, requireCustomer, requireOperator, requireFunder, requireProjectAdmin } from '../middleware/auth';
import { insightsService } from '../services/insightsService';

const router = Router();

// Apply authentication to all insights routes
router.use(authenticateToken);

// Super Admin Insights
router.get('/super-admin', 
  requireSuperAdmin, 
  async (req: Request, res: Response) => {
    try {
      const insights = await insightsService.getSuperAdminInsights();
      res.json(insights);
    } catch (error) {
      console.error('Error getting super admin insights:', error);
      res.status(500).json({ error: 'Failed to get insights' });
    }
  }
);

// Customer Insights
router.get('/customer', 
  requireCustomer, 
  async (req: Request, res: Response) => {
    try {
      if (!req.user?.organizationId) {
        return res.status(400).json({ error: 'Organization ID required' });
      }
      const insights = await insightsService.getCustomerInsights(req.user.organizationId);
      res.json(insights);
    } catch (error) {
      console.error('Error getting customer insights:', error);
      res.status(500).json({ error: 'Failed to get insights' });
    }
  }
);

// Operator Insights
router.get('/operator', 
  requireOperator, 
  async (req: Request, res: Response) => {
    try {
      if (!req.user?.organizationId) {
        return res.status(400).json({ error: 'Organization ID required' });
      }
      const insights = await insightsService.getOperatorInsights(req.user.organizationId);
      res.json(insights);
    } catch (error) {
      console.error('Error getting operator insights:', error);
      res.status(500).json({ error: 'Failed to get insights' });
    }
  }
);

// Funder Insights
router.get('/funder', 
  requireFunder, 
  async (req: Request, res: Response) => {
    try {
      if (!req.user?.organizationId) {
        return res.status(400).json({ error: 'Organization ID required' });
      }
      const insights = await insightsService.getFunderInsights(req.user.organizationId);
      res.json(insights);
    } catch (error) {
      console.error('Error getting funder insights:', error);
      res.status(500).json({ error: 'Failed to get insights' });
    }
  }
);

// Project Admin Insights
router.get('/project-admin', 
  requireProjectAdmin, 
  async (req: Request, res: Response) => {
    try {
      if (!req.user?.projectId) {
        return res.status(400).json({ error: 'Project ID required' });
      }
      const insights = await insightsService.getProjectAdminInsights(req.user.projectId);
      res.json(insights);
    } catch (error) {
      console.error('Error getting project admin insights:', error);
      res.status(500).json({ error: 'Failed to get insights' });
    }
  }
);

export default router;