// Demo Company Data for Nexus Green Platform
// Realistic South African Solar Installation Company

export const demoCompany = {
  id: "demo-001",
  name: "SolarTech Solutions (Pty) Ltd",
  domain: "solartech.nexusgreen.com",
  logo: "/demo-company-logo.png",
  description: "Leading solar energy solutions provider in South Africa",
  address: {
    street: "123 Solar Park Drive",
    city: "Cape Town",
    province: "Western Cape",
    postalCode: "8001",
    country: "South Africa"
  },
  contact: {
    phone: "+27 21 555 0123",
    email: "info@solartech.co.za",
    website: "https://solartech.co.za"
  },
  license: {
    type: "Enterprise",
    maxUsers: 100,
    maxSites: 500,
    features: ["Advanced Analytics", "API Access", "White Label", "Priority Support"],
    monthlyFee: 2500,
    currency: "ZAR",
    billingCycle: "monthly",
    startDate: "2024-01-01",
    endDate: "2024-12-31"
  },
  settings: {
    timezone: "Africa/Johannesburg",
    currency: "ZAR",
    units: {
      power: "kW",
      energy: "kWh",
      temperature: "°C"
    },
    ppaRate: 1.20, // R1.20 per kWh
    tariffStructure: "time-of-use"
  }
};

// Demo Sites Configuration
export const demoSites = [
  {
    id: "site-001",
    name: "Cape Town Industrial Park",
    location: {
      address: "Industrial Park Road, Montague Gardens, Cape Town",
      coordinates: { lat: -33.8567, lng: 18.5108 },
      timezone: "Africa/Johannesburg"
    },
    system: {
      capacity: 250, // kW
      panelCount: 625,
      panelWattage: 400,
      inverterCount: 5,
      inverterCapacity: 50, // kW each
      installDate: "2023-06-15",
      warrantyYears: 25
    },
    financial: {
      installationCost: 3750000, // R3.75M
      ppaRate: 1.20, // R1.20 per kWh
      escalationRate: 0.08, // 8% annual
      contractYears: 20
    },
    performance: {
      expectedAnnualGeneration: 375000, // kWh
      performanceRatio: 0.85,
      degradationRate: 0.005 // 0.5% per year
    }
  },
  {
    id: "site-002", 
    name: "Stellenbosch Wine Estate",
    location: {
      address: "Wine Estate Road, Stellenbosch, Western Cape",
      coordinates: { lat: -33.9321, lng: 18.8602 },
      timezone: "Africa/Johannesburg"
    },
    system: {
      capacity: 150, // kW
      panelCount: 375,
      panelWattage: 400,
      inverterCount: 3,
      inverterCapacity: 50, // kW each
      installDate: "2023-08-20",
      warrantyYears: 25
    },
    financial: {
      installationCost: 2250000, // R2.25M
      ppaRate: 1.20, // R1.20 per kWh
      escalationRate: 0.08, // 8% annual
      contractYears: 20
    },
    performance: {
      expectedAnnualGeneration: 225000, // kWh
      performanceRatio: 0.82,
      degradationRate: 0.005 // 0.5% per year
    }
  }
];

// Weather patterns for Cape Town region (realistic solar irradiance)
export const monthlyIrradianceData = [
  { month: 1, avgIrradiance: 6.8, avgTemp: 26 }, // January
  { month: 2, avgIrradiance: 6.5, avgTemp: 26 }, // February
  { month: 3, avgIrradiance: 5.8, avgTemp: 24 }, // March
  { month: 4, avgIrradiance: 4.5, avgTemp: 21 }, // April
  { month: 5, avgIrradiance: 3.2, avgTemp: 18 }, // May
  { month: 6, avgIrradiance: 2.8, avgTemp: 16 }, // June
  { month: 7, avgIrradiance: 3.1, avgTemp: 16 }, // July
  { month: 8, avgIrradiance: 4.2, avgTemp: 17 }, // August
  { month: 9, avgIrradiance: 5.5, avgTemp: 19 }, // September
  { month: 10, avgIrradiance: 6.2, avgTemp: 22 }, // October
  { month: 11, avgIrradiance: 6.8, avgTemp: 24 }, // November
  { month: 12, avgIrradiance: 7.1, avgTemp: 25 }  // December
];

export default {
  demoCompany,
  demoSites,
  monthlyIrradianceData
};