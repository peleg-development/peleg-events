import React from 'react';
import { Car, Target, PartyPopper, Zap, Skull } from 'lucide-react';

interface Kill {
  id: string;
  killer: string;
  victim: string;
  eventType: string;
  timestamp: number;
}

interface KillFeedProps {
  kills: Kill[];
}

const KillFeed: React.FC<KillFeedProps> = ({ kills }) => {
  const getEventTypeIcon = (eventType: string) => {
    switch (eventType) {
      case 'CarSumo':
        return <Car className="w-4 h-4" />;
      case 'Redzone':
        return <Target className="w-4 h-4" />;
      case 'Party':
        return <PartyPopper className="w-4 h-4" />;
      default:
        return <Zap className="w-4 h-4" />;
    }
  };

  const getEventTypeColor = (eventType: string) => {
    switch (eventType) {
      case 'CarSumo':
        return 'bg-blue-500/20 border-blue-500/50 text-blue-300';
      case 'Redzone':
        return 'bg-red-500/20 border-red-500/50 text-red-300';
      case 'Party':
        return 'bg-purple-500/20 border-purple-500/50 text-purple-300';
      default:
        return 'bg-gray-500/20 border-gray-500/50 text-gray-300';
    }
  };

  return (
    <div className="fixed top-4 right-4 z-50 space-y-2">
      {kills.map((kill) => (
                 <div
           key={kill.id}
           className="bg-gray-900/95 border border-gray-700/50 rounded-lg p-3 max-w-xs transform transition-all duration-300 ease-out shadow-lg"
         >
          <div className="flex items-center space-x-3">
            {/* Event type icon */}
            <div className={`${getEventTypeColor(kill.eventType)} p-2 rounded-lg border flex items-center justify-center`}>
              {getEventTypeIcon(kill.eventType)}
            </div>
            
            {/* Kill info */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center space-x-2 text-sm">
                <span className="text-green-400 font-medium truncate">{kill.killer}</span>
                <Skull className="w-3 h-3 text-red-400 flex-shrink-0" />
                <span className="text-red-400 font-medium truncate">{kill.victim}</span>
              </div>
              
            </div>
          </div>
        </div>
      ))}
      

    </div>
  );
};

export default KillFeed;
