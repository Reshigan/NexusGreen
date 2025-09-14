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
    sm: 'h-6 w-auto',
    md: 'h-8 w-auto', 
    lg: 'h-12 w-auto',
    xl: 'h-16 w-auto'
  };

  const iconSizeClasses = {
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
    <img 
      src="/nexus-green-icon.svg" 
      alt="NexusGreen" 
      className={`${iconSizeClasses[size]} ${className}`}
    />
  );

  const LogoText = () => (
    <span className={`font-bold bg-gradient-to-r from-green-400 via-emerald-500 to-teal-600 bg-clip-text text-transparent ${textSizeClasses[size]} ${className}`}>
      NexusGreen
    </span>
  );

  if (variant === 'icon') {
    return <LogoIcon />;
  }

  if (variant === 'text') {
    return <LogoText />;
  }

  if (variant === 'full') {
    return (
      <img 
        src="/nexus-green-logo.svg" 
        alt="NexusGreen" 
        className={`${sizeClasses[size]} ${className}`}
      />
    );
  }

  return (
    <div className={`flex items-center gap-3 ${className}`}>
      <LogoIcon />
      <LogoText />
    </div>
  );
};

export default NexusGreenLogo;