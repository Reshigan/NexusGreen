"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validate = void 0;
const express_validator_1 = require("express-validator");
const validate = (req, res, next) => {
    const errors = (0, express_validator_1.validationResult)(req);
    if (!errors.isEmpty()) {
        const errorMessages = errors.array().map(error => ({
            field: error.type === 'field' ? error.path : 'unknown',
            message: error.msg,
            value: error.type === 'field' ? error.value : undefined,
        }));
        return res.status(400).json({
            success: false,
            message: 'Validation failed',
            errors: errorMessages,
        });
    }
    next();
};
exports.validate = validate;
//# sourceMappingURL=validation.js.map