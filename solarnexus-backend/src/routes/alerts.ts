import { Router } from 'express';
import { authenticate, requireAnyRole } from '@/middleware/auth';

const router = Router();

router.use(authenticate);
router.use(requireAnyRole);

router.get('/', (req, res) => {
  res.json({ success: true, message: 'Alerts endpoint - coming soon' });
});

export default router;