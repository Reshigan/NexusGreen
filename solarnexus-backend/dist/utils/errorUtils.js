"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getErrorMessage = getErrorMessage;
exports.isError = isError;
function getErrorMessage(error) {
    if (error instanceof Error) {
        return error.message;
    }
    if (typeof error === 'string') {
        return error;
    }
    return 'An unknown error occurred';
}
function isError(error) {
    return error instanceof Error;
}
//# sourceMappingURL=errorUtils.js.map