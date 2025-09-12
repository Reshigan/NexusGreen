-- CreateTable
CREATE TABLE "weather_data" (
    "id" TEXT NOT NULL,
    "siteId" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "temperature" DOUBLE PRECISION NOT NULL,
    "humidity" DOUBLE PRECISION NOT NULL,
    "pressure" DOUBLE PRECISION NOT NULL,
    "windSpeed" DOUBLE PRECISION NOT NULL,
    "windDirection" DOUBLE PRECISION NOT NULL,
    "cloudCover" DOUBLE PRECISION NOT NULL,
    "visibility" DOUBLE PRECISION NOT NULL,
    "uvIndex" DOUBLE PRECISION NOT NULL,
    "description" TEXT NOT NULL,
    "irradiance" DOUBLE PRECISION,
    "performanceRatio" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "weather_data_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "site_metrics" (
    "id" TEXT NOT NULL,
    "siteId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "totalGeneration" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalConsumption" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalGridImport" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalGridExport" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "averageEfficiency" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "capacityFactor" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "availability" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "averageTemperature" DOUBLE PRECISION,
    "lastUpdated" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "site_metrics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sync_stats" (
    "id" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "sitesProcessed" INTEGER NOT NULL DEFAULT 0,
    "recordsUpdated" INTEGER NOT NULL DEFAULT 0,
    "errors" INTEGER NOT NULL DEFAULT 0,
    "duration" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sync_stats_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "weather_data_siteId_timestamp_key" ON "weather_data"("siteId", "timestamp");

-- CreateIndex
CREATE UNIQUE INDEX "site_metrics_siteId_date_key" ON "site_metrics"("siteId", "date");

-- AddForeignKey
ALTER TABLE "weather_data" ADD CONSTRAINT "weather_data_siteId_fkey" FOREIGN KEY ("siteId") REFERENCES "sites"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "site_metrics" ADD CONSTRAINT "site_metrics_siteId_fkey" FOREIGN KEY ("siteId") REFERENCES "sites"("id") ON DELETE CASCADE ON UPDATE CASCADE;