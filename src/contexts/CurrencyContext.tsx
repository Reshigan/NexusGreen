import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { 
  CurrencyCode, 
  DEFAULT_CURRENCY, 
  formatCurrency, 
  convertCurrency,
  CurrencyContextType 
} from '../utils/currency';

const CurrencyContext = createContext<CurrencyContextType | undefined>(undefined);

interface CurrencyProviderProps {
  children: ReactNode;
}

export const CurrencyProvider: React.FC<CurrencyProviderProps> = ({ children }) => {
  const [currentCurrency, setCurrentCurrency] = useState<CurrencyCode>(() => {
    // Load from localStorage or use default
    const saved = localStorage.getItem('nexusgreen-currency');
    return (saved as CurrencyCode) || DEFAULT_CURRENCY;
  });

  // Save to localStorage when currency changes
  useEffect(() => {
    localStorage.setItem('nexusgreen-currency', currentCurrency);
  }, [currentCurrency]);

  const setCurrency = (currency: CurrencyCode) => {
    setCurrentCurrency(currency);
  };

  const formatAmount = (amount: number, options: { compact?: boolean } = {}) => {
    return formatCurrency(amount, currentCurrency, options);
  };

  const convertAmount = (amount: number) => {
    return convertCurrency(amount, currentCurrency);
  };

  const value: CurrencyContextType = {
    currentCurrency,
    setCurrency,
    formatAmount,
    convertAmount,
  };

  return (
    <CurrencyContext.Provider value={value}>
      {children}
    </CurrencyContext.Provider>
  );
};

export const useCurrency = (): CurrencyContextType => {
  const context = useContext(CurrencyContext);
  if (context === undefined) {
    throw new Error('useCurrency must be used within a CurrencyProvider');
  }
  return context;
};

export default CurrencyContext;