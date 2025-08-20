import React, { useState, useEffect } from 'react';
import { Trophy, Crown, Users, DollarSign } from 'lucide-react';

interface WinnerData {
  eventId: string;
  eventType: string;
  winnerName: string;
  winnerId: number;
  reward: {
    type: string;
    data: any;
  };
  participants: number;
}

interface WinnerUIProps {
  winnerData: WinnerData;
  onClose: () => void;
}

const WinnerUI: React.FC<WinnerUIProps> = ({ winnerData, onClose }) => {
  const [showConfetti, setShowConfetti] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setShowConfetti(true);
    }, 500);

    const autoClose = setTimeout(() => {
      onClose();
    }, 10000);

    return () => {
      clearTimeout(timer);
      clearTimeout(autoClose);
    };
  }, [onClose]);

  const formatReward = (reward: any) => {
    if (reward.type === 'money') {
      return `$${(reward.data.amount || 0).toLocaleString()}`;
    } else if (reward.type === 'item') {
      const itemName = reward.data.item || 'Item';
      const amount = reward.data.amount || 1;
      const displayName = itemName.length > 20 ? itemName.substring(0, 17) + '...' : itemName;
      return `${displayName} x${amount}`;
    } else if (reward.type === 'vehicle') {
      return reward.data.vehicle || 'Vehicle';
    }
    return 'Reward';
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

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center">
      {/* Background overlay */}
      <div className="absolute inset-0 bg-black bg-opacity-75"></div>
      
      {/* Confetti effect */}
      {showConfetti && (
        <div className="absolute inset-0 pointer-events-none">
          {[...Array(50)].map((_, i) => (
            <div
              key={i}
              className="absolute animate-bounce"
              style={{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
                animationDelay: `${Math.random() * 2}s`,
                animationDuration: `${1 + Math.random() * 2}s`,
              }}
            >
              <div className={`w-2 h-2 rounded-full ${
                ['bg-yellow-400', 'bg-blue-400', 'bg-green-400', 'bg-red-400', 'bg-purple-400'][Math.floor(Math.random() * 5)]
              }`}></div>
            </div>
          ))}
        </div>
      )}

      {/* Winner card */}
      <div className="relative bg-gradient-to-br from-yellow-400 via-orange-500 to-red-500 rounded-2xl shadow-2xl p-8 max-w-md w-full mx-4 transform animate-pulse">
        {/* Crown icon */}
        <div className="absolute -top-6 left-1/2 transform -translate-x-1/2">
          <Crown className="w-12 h-12 text-yellow-300 drop-shadow-lg" />
        </div>

        {/* Event type */}
        <div className="text-center mb-6">
          <h2 className="text-2xl font-bold text-white mb-2">
            {getEventTypeName(winnerData.eventType)} Event
          </h2>
          <div className="flex items-center justify-center space-x-2 text-white/80">
            <Users className="w-4 h-4" />
            <span>{winnerData.participants} Participants</span>
          </div>
        </div>

        {/* Winner section */}
        <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 mb-6 text-center">
          <div className="flex items-center justify-center mb-4">
            <Trophy className="w-8 h-8 text-yellow-300 mr-2" />
            <h3 className="text-xl font-bold text-white">Winner!</h3>
          </div>
          <div className="text-2xl font-bold text-white mb-2">
            {winnerData.winnerName}
          </div>
          <div className="text-white/80 text-sm">
            Player ID: {winnerData.winnerId}
          </div>
        </div>

        {/* Reward section */}
        <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-center">
          <div className="flex items-center justify-center mb-3">
            <DollarSign className="w-6 h-6 text-yellow-300 mr-2" />
            <h4 className="text-lg font-semibold text-white">Reward</h4>
          </div>
          <div className="text-xl font-bold text-white">
            {formatReward(winnerData.reward)}
          </div>
        </div>

        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-white/70 hover:text-white transition-colors"
        >
          ✕
        </button>
      </div>
    </div>
  );
};

export default WinnerUI;
