import React from 'react';

interface NexusGreenLogoProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  variant?: 'full' | 'icon' | 'text';
  className?: string;
}

const NexusGreenLogo: React.FC<NexusGreenLogoProps> = ({ 
  size = 'md', 
  variant = 'full',
  className = '' 
}) => {
  const sizeClasses = {
    sm: 'h-6 w-6',
    md: 'h-8 w-8', 
    lg: 'h-12 w-12',
    xl: 'h-16 w-16'
  };

  const textSizeClasses = {
    sm: 'text-lg',
    md: 'text-xl',
    lg: 'text-2xl', 
    xl: 'text-3xl'
  };

  const LogoIcon = () => (
    <div className={`relative ${sizeClasses[size]} ${className}`}>
      {/* Outer glow effect */}
      <div className="absolute inset-0 bg-gradient-to-br from-green-400 via-emerald-500 to-teal-600 rounded-full blur-sm opacity-75 animate-pulse"></div>
      
      {/* Main logo shape */}
      <div className="relative w-full h-full bg-gradient-to-br from-green-400 via-emerald-500 to-teal-600 rounded-full flex items-center justify-center shadow-lg">
        {/* Inner design - stylized "N" */}
        <div className="relative w-3/4 h-3/4 flex items-center justify-center">
          {/* Left vertical line */}
          <div className="absolute left-0 top-0 w-1 h-full bg-white rounded-full"></div>
          {/* Right vertical line */}
          <div className="absolute right-0 top-0 w-1 h-full bg-white rounded-full"></div>
          {/* Diagonal line */}
          <div className="absolute w-full h-0.5 bg-white rounded-full transform rotate-45 origin-center"></div>
          {/* Small energy spark */}
          <div className="absolute top-1 right-1 w-1 h-1 bg-yellow-300 rounded-full animate-ping"></div>
        </div>
      </div>
    </div>
  );

  const LogoText = () => (
    <span className={`font-bold bg-gradient-to-r from-green-400 via-emerald-500 to-teal-600 bg-clip-text text-transparent ${textSizeClasses[size]} ${className}`}>
      Nexus Green
    </span>
  );

  if (variant === 'icon') {
    return <LogoIcon />;
  }

  if (variant === 'text') {
    return <LogoText />;
  }

  return (
    <div className={`flex items-center gap-3 ${className}`}>
      <LogoIcon />
      <LogoText />
    </div>
  );
};

export default NexusGreenLogo;