import { Router } from 'express';
import { authenticate, requireSuperAdmin } from '@/middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Get all users (Super Admin only)
router.get('/', requireSuperAdmin, (req, res) => {
  res.json({ success: true, message: 'Users endpoint - coming soon' });
});

// Get user by ID
router.get('/:id', (req, res) => {
  res.json({ success: true, message: 'Get user endpoint - coming soon' });
});

// Update user
router.put('/:id', (req, res) => {
  res.json({ success: true, message: 'Update user endpoint - coming soon' });
});

// Delete user
router.delete('/:id', requireSuperAdmin, (req, res) => {
  res.json({ success: true, message: 'Delete user endpoint - coming soon' });
});

export default router;