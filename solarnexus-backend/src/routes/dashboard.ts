import { Router } from 'express';
import { DashboardController, getInsights } from '../controllers/dashboardController';
import { authenticateToken, requireSuperAdmin, requireCustomer, requireOperator, requireFunder, requireProjectAdmin } from '../middleware/auth';
import { UserRole } from '@prisma/client';

const router = Router();

// Apply authentication to all dashboard routes
router.use(authenticateToken);

// Super Admin Dashboard
router.get('/super-admin', 
  requireSuperAdmin, 
  DashboardController.getSuperAdminDashboard
);

// Customer Dashboard
router.get('/customer', 
  requireCustomer, 
  DashboardController.getCustomerDashboard
);

// Operator Dashboard
router.get('/operator', 
  requireOperator, 
  DashboardController.getOperatorDashboard
);

// Funder Dashboard
router.get('/funder', 
  requireFunder, 
  DashboardController.getFunderDashboard
);

// Project Admin Dashboard
router.get('/project-admin', 
  requireProjectAdmin, 
  DashboardController.getProjectAdminDashboard
);

// Insights endpoint - available to all authenticated users
router.get('/insights', getInsights);

export default router;