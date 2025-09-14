"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("@/middleware/auth");
const router = (0, express_1.Router)();
// All routes require authentication
router.use(auth_1.authenticate);
// Get all users (Super Admin only)
router.get('/', auth_1.requireSuperAdmin, (req, res) => {
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
router.delete('/:id', auth_1.requireSuperAdmin, (req, res) => {
    res.json({ success: true, message: 'Delete user endpoint - coming soon' });
});
exports.default = router;
//# sourceMappingURL=users.js.map