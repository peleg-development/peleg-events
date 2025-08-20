import React, { useState, useEffect } from 'react';
import { X, Users, DollarSign, Car, Target, PartyPopper, Clock } from 'lucide-react';

interface Event {
  id: string;
  type: string;
  hostName: string;
  hostId: number;
  maxPlayers: number;
  currentPlayers: number;
  reward: number;
  rewardType?: string;
  rewardData?: any;
  config: any;
}

interface EventJoinPanelProps {
  event: Event;
  onClose: () => void;
  onJoin: () => void;
  deadline: number; // seconds until event starts
  hasJoined?: boolean;
}

const EventJoinPanel: React.FC<EventJoinPanelProps> = ({ event, onClose, onJoin, deadline, hasJoined = false }) => {
  const [timeLeft, setTimeLeft] = useState(deadline);

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          clearInterval(timer);
          onClose();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [onClose]);

  const getEventIcon = (type: string) => {
    switch (type) {
      case 'CarSumo':
        return <Car className="w-6 h-6" />;
      case 'Redzone':
        return <Target className="w-6 h-6" />;
      case 'Party':
        return <PartyPopper className="w-6 h-6" />;
      default:
        return null;
    }
  };

  const getEventTypeName = (type: string) => {
    switch (type) {
      case 'CarSumo':
        return 'Car Sumo';
      case 'Redzone':
        return 'Redzone';
      case 'Party':
        return 'Party';
      default:
        return type;
    }
  };

  const formatReward = (event: Event) => {
    if (event.rewardType && event.rewardData) {
      switch (event.rewardType) {
        case 'money':
          return `$${(event.rewardData.amount || 0).toLocaleString()}`;
        case 'item':
          const itemName = event.rewardData.item || 'Item';
          const amount = event.rewardData.amount || 1;
          // Truncate long item names
          const displayName = itemName.length > 15 ? itemName.substring(0, 12) + '...' : itemName;
          return `${displayName} x${amount}`;
        case 'vehicle':
          return event.rewardData.vehicle || 'Vehicle';
        default:
          return `$${(event.reward || 0).toLocaleString()}`;
      }
    }
    return `$${(event.reward || 0).toLocaleString()}`;
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="fixed top-4 left-1/2 transform -translate-x-1/2 z-50">
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg shadow-2xl p-6 min-w-[400px] max-w-[500px]">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-3">
            {getEventIcon(event.type)}
            <div>
              <h3 className="text-xl font-bold">{getEventTypeName(event.type)} Event</h3>
              <p className="text-blue-100 text-sm">Hosted by {event.hostName}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 hover:bg-white hover:bg-opacity-20 rounded transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="grid grid-cols-3 gap-4 mb-4">
          <div className="text-center">
            <div className="flex items-center justify-center space-x-1 mb-1">
              <Users className="w-4 h-4" />
              <span className="text-sm">Players</span>
            </div>
            <div className="text-lg font-bold">
              {event.currentPlayers}/{event.maxPlayers}
            </div>
          </div>
          <div className="text-center">
            <div className="flex items-center justify-center space-x-1 mb-1">
              <DollarSign className="w-4 h-4" />
              <span className="text-sm">Reward</span>
            </div>
                         <div className="text-lg font-bold">
               {formatReward(event)}
             </div>
          </div>
          <div className="text-center">
            <div className="flex items-center justify-center space-x-1 mb-1">
              <Clock className="w-4 h-4" />
              <span className="text-sm">Time Left</span>
            </div>
            <div className="text-lg font-bold text-yellow-300">
              {formatTime(timeLeft)}
            </div>
          </div>
        </div>

        <div className="w-full bg-white bg-opacity-20 rounded-full h-2 mb-4">
          <div
            className="bg-yellow-400 h-2 rounded-full transition-all duration-1000"
            style={{ width: `${((deadline - timeLeft) / deadline) * 100}%` }}
          />
        </div>

        <div className="flex space-x-3">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 bg-white bg-opacity-20 hover:bg-opacity-30 rounded-lg transition-colors"
          >
            [H] Decline
          </button>
          <button
            onClick={onJoin}
            className={`flex-1 px-4 py-2 rounded-lg font-semibold transition-colors ${
              hasJoined 
                ? 'bg-red-500 hover:bg-red-600' 
                : 'bg-green-500 hover:bg-green-600'
            }`}
          >
            [G] {hasJoined ? 'Leave Event' : 'Join Event'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default EventJoinPanel;
