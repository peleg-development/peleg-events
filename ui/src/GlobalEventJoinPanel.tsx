import React, { useState, useEffect } from 'react';
import { Users, DollarSign, Car, Target, PartyPopper, Clock } from 'lucide-react';

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

const GlobalEventJoinPanel: React.FC = () => {
  const [event, setEvent] = useState<Event | null>(null);
  const [deadline, setDeadline] = useState(300);
  const [timeLeft, setTimeLeft] = useState(300);
  const [isVisible, setIsVisible] = useState(false);
  const [hasJoined, setHasJoined] = useState(false);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { data } = event;

      if (data.action === 'showGlobalEventJoinPanel') {
        setEvent(data.event);
        setDeadline(data.deadline);
        setTimeLeft(data.deadline);
        setHasJoined(data.hasJoined || false);
        setIsVisible(true);
      } else if (data.action === 'hideGlobalEventJoinPanel') {
        setIsVisible(false);
        setEvent(null);
        setHasJoined(false);
      } else if (data.action === 'updateGlobalEventJoinPanel') {
        setHasJoined(data.hasJoined);
      } else if (data.action === 'playerJoined') {
        // Update player count when someone joins
        setEvent(prev => {
          if (prev && data.eventId === prev.id) {
            return { ...prev, currentPlayers: prev.currentPlayers + 1 };
          }
          return prev;
        });
      } else if (data.action === 'playerLeft') {
        // Update player count when someone leaves
        setEvent(prev => {
          if (prev && data.eventId === prev.id) {
            return { ...prev, currentPlayers: Math.max(0, prev.currentPlayers - 1) };
          }
          return prev;
        });
      }
    };

    const handleHideJoinPanels = () => {
      setIsVisible(false);
      setEvent(null);
      setHasJoined(false);
    };

    window.addEventListener('message', handleMessage);
    window.addEventListener('hideJoinPanels', handleHideJoinPanels);
    
    return () => {
      window.removeEventListener('message', handleMessage);
      window.removeEventListener('hideJoinPanels', handleHideJoinPanels);
    };
  }, []);

  useEffect(() => {
    if (!isVisible || !event) return;

    const timer = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          clearInterval(timer);
          setIsVisible(false);
          setEvent(null);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [isVisible, event]);

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

  const handleJoin = () => {
    if (!event) return;
    if (hasJoined) {
      // Leave the event
      fetch(`https://${(window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'peleg-events'}/leaveEvent`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ eventId: event.id }),
      });
    } else {
      // Join the event
      fetch(`https://${(window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'peleg-events'}/joinEvent`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ eventId: event.id }),
      });
    }
  };

  const handleDecline = () => {
    if (!event) return;
    if (hasJoined) {
      // If already joined, leave the event
      fetch(`https://${(window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'peleg-events'}/leaveEvent`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ eventId: event.id }),
      });
    } else {
      // If not joined, just decline
      fetch(`https://${(window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'peleg-events'}/declineEvent`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ eventId: event.id }),
      });
    }
    setIsVisible(false);
  };

  if (!isVisible || !event) return null;

  return (
    <div className="fixed top-4 left-1/2 transform -translate-x-1/2 z-[9998]">
      <div className="bg-gray-900 border border-gray-700 text-white rounded-lg shadow-2xl p-6 min-w-[400px] max-w-[500px]">
                <div className="flex items-center space-x-3 mb-4">
          {getEventIcon(event.type)}
          <div>
            <h3 className="text-xl font-bold">{getEventTypeName(event.type)} Event</h3>
            <p className="text-gray-400 text-sm">Hosted by {event.hostName}</p>
          </div>
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

        <div className="w-full bg-gray-700 rounded-full h-2 mb-4">
          <div
            className="bg-blue-500 h-2 rounded-full transition-all duration-1000"
            style={{ width: `${((deadline - timeLeft) / deadline) * 100}%` }}
          />
        </div>

        <div className="flex space-x-3">
          <button
            onClick={handleDecline}
            className="flex-1 px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors"
          >
            [H] {hasJoined ? 'Leave & Close' : 'Decline'}
          </button>
          <button
            onClick={handleJoin}
            className={`flex-1 px-4 py-2 rounded-lg font-semibold transition-colors ${
              hasJoined 
                ? 'bg-red-600 hover:bg-red-700' 
                : 'bg-blue-600 hover:bg-blue-700'
            }`}
          >
            [G] {hasJoined ? 'Leave Event' : 'Join Event'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default GlobalEventJoinPanel;
