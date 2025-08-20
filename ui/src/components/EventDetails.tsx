import React from 'react';
import { X, Users, DollarSign, Play, LogIn, Car, Target, PartyPopper } from 'lucide-react';

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

interface EventDetailsProps {
  event: Event;
  currentPlayerId: number | null;
  isDarkMode?: boolean;
  onClose: () => void;
  onJoin: () => void;
  onStart: () => void;
  onStop?: () => void;
  isEventActive?: boolean;
}

const EventDetails: React.FC<EventDetailsProps> = ({ event, currentPlayerId, isDarkMode = false, onClose, onJoin, onStart, onStop }) => {
  const getEventIcon = (type: string) => {
    switch (type) {
      case 'CarSumo':
        return <Car className="w-8 h-8" />;
      case 'Redzone':
        return <Target className="w-8 h-8" />;
      case 'Party':
        return <PartyPopper className="w-8 h-8" />;
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

  const getEventDescription = (type: string) => {
    switch (type) {
      case 'CarSumo':
        return 'Fight to the death in cars above the sky! Last player to stay on the ring wins.';
      case 'Redzone':
        return 'Last man standing in the redzone! Stay within the zone and eliminate your opponents.';
      case 'Party':
        return 'Join the party at the host\'s location! A fun gathering for all participants.';
      default:
        return 'An exciting event for all participants!';
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
          const displayName = itemName.length > 20 ? itemName.substring(0, 17) + '...' : itemName;
          return `${displayName} x${amount}`;
        case 'vehicle':
          return event.rewardData.vehicle || 'Vehicle';
        default:
          return `$${(event.reward || 0).toLocaleString()}`;
      }
    }
    return `$${(event.reward || 0).toLocaleString()}`;
  };

  const isHost = currentPlayerId === event.hostId;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className={`text-2xl font-bold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>Event Details</h2>
        <button
          onClick={onClose}
          className={`p-2 rounded-lg transition-colors ${isDarkMode ? 'hover:bg-gray-700' : 'hover:bg-gray-100'}`}
        >
          <X className="w-5 h-5" />
        </button>
      </div>

      {/* Event Header */}
      <div className="bg-gradient-to-r from-primary to-blue-600 text-white rounded-lg p-6">
        <div className="flex items-center space-x-4">
          {getEventIcon(event.type)}
          <div>
            <h3 className="text-2xl font-bold">{getEventTypeName(event.type)}</h3>
            <p className="text-blue-100">{getEventDescription(event.type)}</p>
          </div>
        </div>
      </div>

      {/* Event Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className={`${isDarkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'} border rounded-lg p-4`}>
          <div className="flex items-center space-x-2 mb-2">
            <Users className="w-5 h-5 text-gray-400" />
            <span className={`text-sm ${isDarkMode ? 'text-gray-300' : 'text-gray-600'}`}>Players</span>
          </div>
          <div className={`text-2xl font-bold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
            {event.type === 'Party' ? `${event.currentPlayers}/∞` : `${event.currentPlayers}/${event.maxPlayers}`}
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
            <div
              className="bg-primary h-2 rounded-full transition-all duration-300"
              style={{ width: event.type === 'Party' ? '100%' : `${(event.currentPlayers / event.maxPlayers) * 100}%` }}
            />
          </div>
        </div>

        <div className={`${isDarkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'} border rounded-lg p-4`}>
          <div className="flex items-center space-x-2 mb-2">
            <DollarSign className="w-5 h-5 text-gray-400" />
            <span className={`text-sm ${isDarkMode ? 'text-gray-300' : 'text-gray-600'}`}>Reward</span>
          </div>
                     <div className="text-2xl font-bold text-primary">
             {formatReward(event)}
           </div>
        </div>

        <div className={`${isDarkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'} border rounded-lg p-4`}>
          <div className={`text-sm mb-2 ${isDarkMode ? 'text-gray-300' : 'text-gray-600'}`}>Host</div>
          <div className={`text-lg font-semibold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>{event.hostName}</div>
        </div>
      </div>

      {/* Event Rules */}
      <div className={`${isDarkMode ? 'bg-gray-800' : 'bg-gray-50'} rounded-lg p-6`}>
        <h4 className={`text-lg font-semibold mb-4 ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>Event Rules</h4>
        <div className={`space-y-3 text-sm ${isDarkMode ? 'text-gray-300' : 'text-gray-600'}`}>
          {event.type === 'CarSumo' && (
            <>
              <div>• Players are teleported to a sky ring in vehicles</div>
              <div>• Last player to stay on the ring wins</div>
              <div>• Falling below the ring results in elimination</div>
              <div>• Vehicles explode when players are eliminated</div>
            </>
          )}
          {event.type === 'Redzone' && (
            <>
              <div>• Players spawn in different locations within the zone</div>
              <div>• Stay within the redzone boundaries</div>
              <div>• Last man standing wins</div>
              <div>• Infinite ammo is provided</div>
            </>
          )}
          {event.type === 'Party' && (
            <>
              <div>• All participants are teleported to the host's location</div>
              <div>• Everyone receives a reward upon completion</div>
              <div>• A fun social gathering event</div>
            </>
          )}
        </div>
      </div>

      {/* Action Buttons */}
      <div className={`flex items-center justify-end space-x-4 pt-6 border-t ${isDarkMode ? 'border-gray-700' : 'border-gray-200'}`}>
        <button
          onClick={onClose}
          className={`px-6 py-2 border rounded-lg transition-colors ${isDarkMode ? 'border-gray-600 text-gray-300 hover:bg-gray-700' : 'border-gray-300 text-gray-700 hover:bg-gray-50'}`}
        >
          Close
        </button>
        
        {isHost ? (
          event.type === 'Party' ? (
            <button
              onClick={onStop}
              className="px-6 py-2 bg-danger hover:bg-red-600 text-white rounded-lg flex items-center space-x-2 transition-colors"
            >
              <X className="w-4 h-4" />
              <span>End Event</span>
            </button>
          ) : (
            <button
              onClick={onStart}
              className="px-6 py-2 bg-success hover:bg-green-600 text-white rounded-lg flex items-center space-x-2 transition-colors"
            >
              <Play className="w-4 h-4" />
              <span>Start Event</span>
            </button>
          )
        ) : (
          <button
            onClick={onJoin}
            className="px-6 py-2 bg-primary hover:bg-blue-600 text-white rounded-lg flex items-center space-x-2 transition-colors"
          >
            <LogIn className="w-4 h-4" />
            <span>Join Event</span>
          </button>
        )}
      </div>
    </div>
  );
};

export default EventDetails;
