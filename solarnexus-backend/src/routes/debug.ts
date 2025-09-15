import { Router } from 'express';
import { prisma } from '@/utils/database';

const router = Router();

console.log('Debug route module loaded!');

// Simple test endpoint
router.get('/test', (req, res) => {
  res.json({ message: 'Debug route is working!' });
});

// Debug endpoint to check user data
router.get('/user/:email', async (req, res) => {
  try {
    const { email } = req.params;
    
    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        organizationId: true,
        projectId: true,
        isActive: true,
        organization: {
          select: {
            id: true,
            name: true,
            slug: true,
            isActive: true,
          },
        },
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      user,
      hasProjectId: !!user.projectId,
      projectIdValue: user.projectId,
    });
  } catch (error) {
    console.error('Debug endpoint error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;