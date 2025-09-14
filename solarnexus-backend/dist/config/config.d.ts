export declare const config: {
    port: number;
    host: string;
    nodeEnv: string;
    databaseUrl: string;
    jwt: {
        secret: string;
        expiresIn: string;
        refreshSecret: string;
        refreshExpiresIn: string;
    };
    redisUrl: string;
    email: {
        host: string;
        port: number;
        user: string;
        pass: string;
        from: string;
        fromName: string;
    };
    solax: {
        baseUrl: string;
        clientId: string;
        clientSecret: string;
    };
    weatherApiKey: string;
    municipalRatesApiKey: string;
    upload: {
        maxFileSize: number;
        uploadPath: string;
    };
    bcryptRounds: number;
    rateLimit: {
        windowMs: number;
        maxRequests: number;
    };
    logLevel: string;
    enableMetrics: boolean;
    productionServerIp: string;
    ssl: {
        certPath: string;
        keyPath: string;
    };
};
//# sourceMappingURL=config.d.ts.map