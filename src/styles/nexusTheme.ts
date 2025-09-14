// NexusGreen Modern Theme Configuration
// Glassmorphism, gradients, and modern design system

export const nexusTheme = {
  // Color Palette - Modern Solar Energy Theme
  colors: {
    // Primary - Solar Energy Inspired
    primary: {
      50: '#f0fdf4',
      100: '#dcfce7',
      200: '#bbf7d0',
      300: '#86efac',
      400: '#4ade80',
      500: '#22c55e', // Main brand color
      600: '#16a34a',
      700: '#15803d',
      800: '#166534',
      900: '#14532d',
      950: '#052e16'
    },
    
    // Secondary - Energy Blue
    secondary: {
      50: '#eff6ff',
      100: '#dbeafe',
      200: '#bfdbfe',
      300: '#93c5fd',
      400: '#60a5fa',
      500: '#3b82f6',
      600: '#2563eb',
      700: '#1d4ed8',
      800: '#1e40af',
      900: '#1e3a8a',
      950: '#172554'
    },
    
    // Accent - Solar Orange
    accent: {
      50: '#fff7ed',
      100: '#ffedd5',
      200: '#fed7aa',
      300: '#fdba74',
      400: '#fb923c',
      500: '#f97316',
      600: '#ea580c',
      700: '#c2410c',
      800: '#9a3412',
      900: '#7c2d12',
      950: '#431407'
    },
    
    // Status Colors
    success: '#10b981',
    warning: '#f59e0b',
    error: '#ef4444',
    info: '#3b82f6',
    
    // Neutral Grays
    gray: {
      50: '#f9fafb',
      100: '#f3f4f6',
      200: '#e5e7eb',
      300: '#d1d5db',
      400: '#9ca3af',
      500: '#6b7280',
      600: '#4b5563',
      700: '#374151',
      800: '#1f2937',
      900: '#111827',
      950: '#030712'
    }
  },
  
  // Glassmorphism Effects
  glass: {
    // Light glassmorphism
    light: {
      background: 'rgba(255, 255, 255, 0.25)',
      backdropFilter: 'blur(16px)',
      border: '1px solid rgba(255, 255, 255, 0.18)',
      boxShadow: '0 8px 32px 0 rgba(31, 38, 135, 0.37)'
    },
    
    // Dark glassmorphism
    dark: {
      background: 'rgba(17, 24, 39, 0.25)',
      backdropFilter: 'blur(16px)',
      border: '1px solid rgba(255, 255, 255, 0.125)',
      boxShadow: '0 8px 32px 0 rgba(0, 0, 0, 0.37)'
    },
    
    // Colored glassmorphism
    primary: {
      background: 'rgba(34, 197, 94, 0.15)',
      backdropFilter: 'blur(16px)',
      border: '1px solid rgba(34, 197, 94, 0.2)',
      boxShadow: '0 8px 32px 0 rgba(34, 197, 94, 0.2)'
    },
    
    secondary: {
      background: 'rgba(59, 130, 246, 0.15)',
      backdropFilter: 'blur(16px)',
      border: '1px solid rgba(59, 130, 246, 0.2)',
      boxShadow: '0 8px 32px 0 rgba(59, 130, 246, 0.2)'
    }
  },
  
  // Gradients
  gradients: {
    // Primary gradients
    solarSunrise: 'linear-gradient(135deg, #f97316 0%, #fb923c 25%, #fbbf24 50%, #facc15 75%, #eab308 100%)',
    solarSunset: 'linear-gradient(135deg, #dc2626 0%, #ea580c 25%, #f97316 50%, #fb923c 75%, #fbbf24 100%)',
    energyFlow: 'linear-gradient(135deg, #22c55e 0%, #16a34a 25%, #15803d 50%, #166534 75%, #14532d 100%)',
    
    // Background gradients
    lightBg: 'linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 25%, #f0fdf4 50%, #ecfdf5 75%, #f7fee7 100%)',
    darkBg: 'linear-gradient(135deg, #0f172a 0%, #1e293b 25%, #334155 50%, #475569 75%, #64748b 100%)',
    
    // Card gradients
    cardLight: 'linear-gradient(135deg, rgba(255, 255, 255, 0.9) 0%, rgba(255, 255, 255, 0.7) 100%)',
    cardDark: 'linear-gradient(135deg, rgba(17, 24, 39, 0.9) 0%, rgba(31, 41, 55, 0.7) 100%)',
    
    // Status gradients
    success: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
    warning: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
    error: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
    info: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)'
  },
  
  // Shadows
  shadows: {
    // Soft shadows
    soft: {
      sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
      md: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
      lg: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
      xl: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)'
    },
    
    // Colored shadows
    primary: '0 10px 15px -3px rgba(34, 197, 94, 0.3), 0 4px 6px -2px rgba(34, 197, 94, 0.15)',
    secondary: '0 10px 15px -3px rgba(59, 130, 246, 0.3), 0 4px 6px -2px rgba(59, 130, 246, 0.15)',
    accent: '0 10px 15px -3px rgba(249, 115, 22, 0.3), 0 4px 6px -2px rgba(249, 115, 22, 0.15)',
    
    // Glow effects
    glow: {
      primary: '0 0 20px rgba(34, 197, 94, 0.5)',
      secondary: '0 0 20px rgba(59, 130, 246, 0.5)',
      accent: '0 0 20px rgba(249, 115, 22, 0.5)',
      success: '0 0 20px rgba(16, 185, 129, 0.5)',
      warning: '0 0 20px rgba(245, 158, 11, 0.5)',
      error: '0 0 20px rgba(239, 68, 68, 0.5)'
    }
  }
};

// Utility functions for theme usage
export const getGlassStyle = (variant: 'light' | 'dark' | 'primary' | 'secondary' = 'light') => {
  return nexusTheme.glass[variant];
};

export const getGradient = (name: keyof typeof nexusTheme.gradients) => {
  return nexusTheme.gradients[name];
};

export default nexusTheme;