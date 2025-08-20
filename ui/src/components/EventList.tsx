import React from 'react';
import { Users, Trophy, Car, Target, PartyPopper } from 'lucide-react';

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
  status?: string;
}

interface EventListProps {
  events: Event[];
  isDarkMode?: boolean;
  onEventClick: (event: Event) => void;
}

const EventList: React.FC<EventListProps> = ({ events, isDarkMode = false, onEventClick }) => {
  const getEventIcon = (type: string) => {
    switch (type) {
      case 'CarSumo':
        return <Car className="w-5 h-5" />;
      case 'Redzone':
        return <Target className="w-5 h-5" />;
      case 'Party':
        return <PartyPopper className="w-5 h-5" />;
      default:
        return <Trophy className="w-5 h-5" />;
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

  const formatRewardType = (event: Event) => {
    if (event.rewardType) {
      switch (event.rewardType) {
        case 'money':
          return 'Money';
        case 'item':
          return 'Item';
        case 'vehicle':
          return 'Vehicle';
        default:
          return 'Reward';
      }
    }
    return 'Reward';
  };


  if (events.length === 0) {
    return (
      <div className="text-center py-12">
        <Trophy className="w-16 h-16 text-gray-300 mx-auto mb-4" />
        <h3 className={`text-lg font-medium mb-2 ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>No Active Events</h3>
        <p className={isDarkMode ? 'text-gray-400' : 'text-gray-500'}>Create an event to get started!</p>
      </div>
    );
  }

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {events.map((event) => (
        <div
          key={event.id}
          onClick={() => onEventClick(event)}
          className={`${isDarkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'} border rounded-lg p-6 hover:shadow-lg transition-shadow cursor-pointer`}
        >
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-2">
              {getEventIcon(event.type)}
              <span className={`font-semibold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                {getEventTypeName(event.type)}
              </span>
              {event.status === 'active' && event.type === 'Party' && (
                <span className="px-2 py-1 text-xs bg-green-500 text-white rounded-full">
                  Active
                </span>
              )}
            </div>
                         <div className="text-right">
               <div className="text-2xl font-bold text-primary">{formatRewardType(event)}</div>
               <div className="text-sm text-gray-500">Reward Type</div>
             </div>
          </div>

                      <div className="space-y-3">
              <div className="flex items-center justify-between text-sm">
                <span className={isDarkMode ? 'text-gray-300' : 'text-gray-600'}>Host:</span>
                <span className={`font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>{event.hostName}</span>
              </div>

              <div className="flex items-center justify-between text-sm">
                <span className={isDarkMode ? 'text-gray-300' : 'text-gray-600'}>Players:</span>
                <div className="flex items-center space-x-1">
                  <Users className="w-4 h-4 text-gray-400" />
                  <span className={`font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                    {event.type === 'Party' ? `${event.currentPlayers}/∞` : `${event.currentPlayers}/${event.maxPlayers}`}
                  </span>
                </div>
              </div>

            <div className="w-full bg-gray-200 rounded-full h-2">
              <div
                className="bg-primary h-2 rounded-full transition-all duration-300"
                style={{ width: event.type === 'Party' ? '100%' : `${(event.currentPlayers / event.maxPlayers) * 100}%` }}
              />
            </div>
          </div>

                      <div className={`mt-4 pt-4 border-t ${isDarkMode ? 'border-gray-700' : 'border-gray-100'}`}>
              <button className="w-full bg-primary hover:bg-blue-600 text-white py-2 px-4 rounded-lg transition-colors">
                View Details
              </button>
            </div>
        </div>
      ))}
    </div>
  );
};

export default EventList;
