"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("@/middleware/auth");
const router = (0, express_1.Router)();
router.use(auth_1.authenticate);
router.use(auth_1.requireAnyRole);
router.get('/', (req, res) => {
    res.json({ success: true, message: 'SDG metrics endpoint - coming soon' });
});
exports.default = router;
//# sourceMappingURL=sdg.js.map