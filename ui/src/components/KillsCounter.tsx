import React from 'react';
import { Target } from 'lucide-react';

interface KillsCounterProps {
  kills: number;
  isVisible: boolean;
}

const KillsCounter: React.FC<KillsCounterProps> = ({ kills, isVisible }) => {
  if (!isVisible) return null;
  
  return (
    <div className="fixed top-4 left-4 z-[9998] group">
      <div 
        className="relative bg-black/85 backdrop-blur-sm p-6 transition-all duration-300 group-hover:scale-105"
        style={{
          clipPath: 'polygon(0% 25%, 0% 75%, 25% 100%, 75% 100%, 100% 75%, 100% 25%, 75% 0%, 25% 0%)'
        }}
      >
        <div className="flex flex-col items-center justify-center space-y-2">
          <Target className="w-6 h-6 text-orange-400 transition-colors group-hover:text-orange-300" />
          <div className="text-center">
            <div className="text-xs font-medium text-gray-400 uppercase tracking-wider">
              Kills
            </div>
            <div className="text-2xl font-bold text-white font-mono">
              {kills}
            </div>
          </div>
        </div>
        
        {/* Animated border */}
        <div 
          className="absolute inset-0 border-2 border-orange-500/50 transition-all duration-300 group-hover:border-orange-400"
          style={{
            clipPath: 'polygon(0% 25%, 0% 75%, 25% 100%, 75% 100%, 100% 75%, 100% 25%, 75% 0%, 25% 0%)'
          }}
        ></div>
      </div>
    </div>
  );
};
export default KillsCounter;
