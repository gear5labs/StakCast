import React, { useState, useEffect, ReactNode } from 'react';

interface DelayedContentProps {
  children: ReactNode; 
}

const DelayedContent: React.FC<DelayedContentProps> = ({ children }) => {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const timeout = setTimeout(() => setIsVisible(true), 1000);
    return () => clearTimeout(timeout); 
  }, []);

  return isVisible ? <>{children}</> : null; 
};

export default DelayedContent;
