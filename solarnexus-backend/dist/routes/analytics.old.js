"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const client_1 = require("@prisma/client");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
const prisma = new client_1.PrismaClient();
// Simple customer analytics endpoint
router.get('/customer/:userId', auth_1.authenticateToken, async (req, res) => {
    try {
        const { userId } = req.params;
        // Get user's sites
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                organization: {
                    include: {
                        sites: {
                            include: {
                                energyData: {
                                    take: 100,
                                    orderBy: { timestamp: 'desc' }
                                }
                            }
                        }
                    }
                }
            }
        });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        // Calculate basic analytics
        const sites = user.organization.sites;
        const totalSites = sites.length;
        let totalGeneration = 0;
        let totalConsumption = 0;
        sites.forEach(site => {
            site.energyData.forEach(data => {
                totalGeneration += data.solarGeneration || 0;
                totalConsumption += data.gridConsumption || 0;
            });
        });
        res.json({
            totalSites,
            totalGeneration,
            totalConsumption,
            savings: Math.max(0, totalGeneration - totalConsumption),
            sites: sites.map(site => ({
                id: site.id,
                name: site.name,
                capacity: site.capacity,
                isActive: site.isActive
            }))
        });
    }
    catch (error) {
        console.error('Customer analytics error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
// Simple funder analytics endpoint
router.get('/funder/:userId', auth_1.authenticateToken, async (req, res) => {
    try {
        const { userId } = req.params;
        // Get funder's projects
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                organization: {
                    include: {
                        sites: true
                    }
                }
            }
        });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        const sites = user.organization.sites;
        const totalCapacity = sites.reduce((sum, site) => sum + site.capacity, 0);
        const activeSites = sites.filter(site => site.isActive).length;
        res.json({
            totalSites: sites.length,
            activeSites,
            totalCapacity,
            sites: sites.map(site => ({
                id: site.id,
                name: site.name,
                capacity: site.capacity,
                isActive: site.isActive,
                installDate: site.installDate
            }))
        });
    }
    catch (error) {
        console.error('Funder analytics error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
// Simple O&M analytics endpoint
router.get('/om/:userId', auth_1.authenticateToken, async (req, res) => {
    try {
        const { userId } = req.params;
        // Get O&M provider's sites
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                organization: {
                    include: {
                        sites: {
                            include: {
                                alerts: {
                                    where: { status: 'OPEN' },
                                    take: 10,
                                    orderBy: { createdAt: 'desc' }
                                }
                            }
                        }
                    }
                }
            }
        });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        const sites = user.organization.sites;
        const totalAlerts = sites.reduce((sum, site) => sum + site.alerts.length, 0);
        const criticalAlerts = sites.reduce((sum, site) => sum + site.alerts.filter(alert => alert.severity === 'CRITICAL').length, 0);
        res.json({
            totalSites: sites.length,
            totalAlerts,
            criticalAlerts,
            sites: sites.map(site => ({
                id: site.id,
                name: site.name,
                capacity: site.capacity,
                isActive: site.isActive,
                alertCount: site.alerts.length
            }))
        });
    }
    catch (error) {
        console.error('O&M analytics error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
// Health check endpoint
router.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
exports.default = router;
//# sourceMappingURL=analytics.old.js.map