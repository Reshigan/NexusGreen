import React from 'react';
import { motion } from 'framer-motion';
import { cn } from '../../lib/utils';

interface ModernCardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  hover?: boolean;
  gradient?: boolean;
  glass?: boolean;
}

export const ModernCard: React.FC<ModernCardProps> = ({ 
  children, 
  className, 
  hover = true, 
  gradient = false,
  glass = false,
  ...props 
}) => {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={hover ? { y: -2, scale: 1.02 } : undefined}
      transition={{ duration: 0.2 }}
      className={cn(
        "rounded-2xl border shadow-sm transition-all duration-200",
        glass 
          ? "bg-white/80 dark:bg-slate-800/80 backdrop-blur-xl border-slate-200/50 dark:border-slate-700/50" 
          : "bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700",
        gradient && "bg-gradient-to-br from-white to-slate-50 dark:from-slate-800 dark:to-slate-900",
        hover && "hover:shadow-lg hover:shadow-slate-200/50 dark:hover:shadow-slate-900/50",
        className
      )}
      {...props}
    >
      {children}
    </motion.div>
  );
};

interface ModernCardHeaderProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

export const ModernCardHeader: React.FC<ModernCardHeaderProps> = ({ 
  children, 
  className, 
  ...props 
}) => {
  return (
    <div
      className={cn(
        "flex flex-col space-y-1.5 p-6 pb-4",
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
};

interface ModernCardTitleProps extends React.HTMLAttributes<HTMLHeadingElement> {
  children: React.ReactNode;
}

export const ModernCardTitle: React.FC<ModernCardTitleProps> = ({ 
  children, 
  className, 
  ...props 
}) => {
  return (
    <h3
      className={cn(
        "text-lg font-semibold leading-none tracking-tight text-slate-900 dark:text-slate-100",
        className
      )}
      {...props}
    >
      {children}
    </h3>
  );
};

interface ModernCardDescriptionProps extends React.HTMLAttributes<HTMLParagraphElement> {
  children: React.ReactNode;
}

export const ModernCardDescription: React.FC<ModernCardDescriptionProps> = ({ 
  children, 
  className, 
  ...props 
}) => {
  return (
    <p
      className={cn(
        "text-sm text-slate-600 dark:text-slate-400",
        className
      )}
      {...props}
    >
      {children}
    </p>
  );
};

interface ModernCardContentProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

export const ModernCardContent: React.FC<ModernCardContentProps> = ({ 
  children, 
  className, 
  ...props 
}) => {
  return (
    <div
      className={cn(
        "p-6 pt-0",
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
};

interface ModernCardFooterProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

export const ModernCardFooter: React.FC<ModernCardFooterProps> = ({ 
  children, 
  className, 
  ...props 
}) => {
  return (
    <div
      className={cn(
        "flex items-center p-6 pt-0",
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
};