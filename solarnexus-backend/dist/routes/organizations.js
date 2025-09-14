"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("@/middleware/auth");
const router = (0, express_1.Router)();
// All routes require authentication
router.use(auth_1.authenticate);
// Get all organizations (Super Admin only)
router.get('/', auth_1.requireSuperAdmin, (req, res) => {
    res.json({ success: true, message: 'Organizations endpoint - coming soon' });
});
// Get current organization
router.get('/current', (req, res) => {
    res.json({ success: true, message: 'Current organization endpoint - coming soon' });
});
// Update organization
router.put('/:id', (req, res) => {
    res.json({ success: true, message: 'Update organization endpoint - coming soon' });
});
exports.default = router;
//# sourceMappingURL=organizations.js.map