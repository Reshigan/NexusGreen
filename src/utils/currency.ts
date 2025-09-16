// Currency utility for NexusGreen
// Supports multiple currencies including USD and RAND (South African Rand)

export type CurrencyCode = 'USD' | 'RAND' | 'EUR' | 'GBP';

export interface CurrencyConfig {
  code: CurrencyCode;
  symbol: string;
  name: string;
  exchangeRate: number; // Rate to USD
  locale: string;
  decimalPlaces: number;
}

// Currency configurations
export const CURRENCIES: Record<CurrencyCode, CurrencyConfig> = {
  USD: {
    code: 'USD',
    symbol: '$',
    name: 'US Dollar',
    exchangeRate: 1.0,
    locale: 'en-US',
    decimalPlaces: 2,
  },
  RAND: {
    code: 'RAND',
    symbol: 'R',
    name: 'South African Rand',
    exchangeRate: 18.5, // Approximate rate: 1 USD = 18.5 RAND
    locale: 'en-ZA',
    decimalPlaces: 2,
  },
  EUR: {
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    exchangeRate: 0.85,
    locale: 'de-DE',
    decimalPlaces: 2,
  },
  GBP: {
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    exchangeRate: 0.75,
    locale: 'en-GB',
    decimalPlaces: 2,
  },
};

// Default currency
export const DEFAULT_CURRENCY: CurrencyCode = 'USD';

// Get currency configuration
export const getCurrency = (code: CurrencyCode = DEFAULT_CURRENCY): CurrencyConfig => {
  return CURRENCIES[code] || CURRENCIES[DEFAULT_CURRENCY];
};

// Convert amount from USD to target currency
export const convertCurrency = (
  amountUSD: number,
  targetCurrency: CurrencyCode = DEFAULT_CURRENCY
): number => {
  const currency = getCurrency(targetCurrency);
  return amountUSD * currency.exchangeRate;
};

// Format currency amount
export const formatCurrency = (
  amount: number,
  currencyCode: CurrencyCode = DEFAULT_CURRENCY,
  options: {
    compact?: boolean;
    showSymbol?: boolean;
    showCode?: boolean;
  } = {}
): string => {
  const {
    compact = false,
    showSymbol = true,
    showCode = false,
  } = options;

  const currency = getCurrency(currencyCode);
  const convertedAmount = convertCurrency(amount, currencyCode);

  let formattedAmount: string;

  if (compact && Math.abs(convertedAmount) >= 1000) {
    // Format as compact (e.g., $125.7k, R2.3M)
    if (Math.abs(convertedAmount) >= 1000000) {
      formattedAmount = (convertedAmount / 1000000).toFixed(1) + 'M';
    } else {
      formattedAmount = (convertedAmount / 1000).toFixed(1) + 'k';
    }
  } else {
    // Format as full number with locale
    formattedAmount = new Intl.NumberFormat(currency.locale, {
      minimumFractionDigits: currency.decimalPlaces,
      maximumFractionDigits: currency.decimalPlaces,
    }).format(convertedAmount);
  }

  // Build final string
  let result = '';
  if (showSymbol) {
    result += currency.symbol;
  }
  result += formattedAmount;
  if (showCode) {
    result += ` ${currency.code}`;
  }

  return result;
};

// Format currency for display in cards (compact format)
export const formatCurrencyCompact = (
  amount: number,
  currencyCode: CurrencyCode = DEFAULT_CURRENCY
): string => {
  return formatCurrency(amount, currencyCode, { compact: true });
};

// Format currency for detailed views (full format)
export const formatCurrencyFull = (
  amount: number,
  currencyCode: CurrencyCode = DEFAULT_CURRENCY
): string => {
  return formatCurrency(amount, currencyCode, { compact: false });
};

// Get all available currencies for selection
export const getAvailableCurrencies = (): CurrencyConfig[] => {
  return Object.values(CURRENCIES);
};

// Currency context for React components
export interface CurrencyContextType {
  currentCurrency: CurrencyCode;
  setCurrency: (currency: CurrencyCode) => void;
  formatAmount: (amount: number, options?: { compact?: boolean }) => string;
  convertAmount: (amount: number) => number;
}