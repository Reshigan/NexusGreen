import React from 'react';
import { Button } from './ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from './ui/dropdown-menu';
import { DollarSign, ChevronDown } from 'lucide-react';
import { useCurrency } from '../contexts/CurrencyContext';
import { getAvailableCurrencies, getCurrency } from '../utils/currency';

interface CurrencySelectorProps {
  variant?: 'default' | 'outline' | 'ghost';
  size?: 'sm' | 'default' | 'lg';
  showLabel?: boolean;
}

export const CurrencySelector: React.FC<CurrencySelectorProps> = ({
  variant = 'outline',
  size = 'sm',
  showLabel = true,
}) => {
  const { currentCurrency, setCurrency } = useCurrency();
  const currencies = getAvailableCurrencies();
  const current = getCurrency(currentCurrency);

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant={variant} size={size} className="gap-2">
          <DollarSign className="w-4 h-4" />
          {showLabel && (
            <>
              <span>{current.symbol}</span>
              <span className="hidden sm:inline">{current.code}</span>
            </>
          )}
          <ChevronDown className="w-4 h-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48">
        {currencies.map((currency) => (
          <DropdownMenuItem
            key={currency.code}
            onClick={() => setCurrency(currency.code)}
            className={`flex items-center gap-3 ${
              currentCurrency === currency.code ? 'bg-accent' : ''
            }`}
          >
            <span className="font-mono text-lg">{currency.symbol}</span>
            <div className="flex flex-col">
              <span className="font-medium">{currency.code}</span>
              <span className="text-xs text-muted-foreground">{currency.name}</span>
            </div>
            {currentCurrency === currency.code && (
              <div className="ml-auto w-2 h-2 bg-primary rounded-full" />
            )}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
};

export default CurrencySelector;