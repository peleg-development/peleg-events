import React, { useState, useEffect } from 'react';
import { Trophy, Clock, Target, Users, Medal } from 'lucide-react';
import { fetchNui } from '../utils/fetchNui';

interface PlayerStats {
  id: number;
  name: string;
  kills: number;
  timeAlive: number;
  rank: number;
  isWinner?: boolean;
}

interface ScoreboardData {
  eventId: string;
  eventType: string;
  players: PlayerStats[];
  duration: number;
}

interface ScoreboardProps {
  scoreboardData: ScoreboardData;
  onClose: () => void;
}

const Scoreboard: React.FC<ScoreboardProps> = ({ scoreboardData, onClose }) => {
  const [showConfetti, setShowConfetti] = useState(false);
  const [timeLeft, setTimeLeft] = useState(20);

  useEffect(() => {
    fetchNui('setNuiFocus', { focus: true, cursor: true });

    const timer = setTimeout(() => {
      setShowConfetti(true);
    }, 500);

    const countdown = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          onClose();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => {
      clearTimeout(timer);
      clearInterval(countdown);
      fetchNui('setNuiFocus', { focus: false, cursor: false });
    };
  }, [onClose]);

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

  const formatTime = (seconds: number) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  const getRankIcon = (rank: number) => {
    switch (rank) {
      case 1:
        return <Medal className="w-5 h-5 text-yellow-400" />;
      case 2:
        return <Medal className="w-5 h-5 text-gray-400" />;
      case 3:
        return <Medal className="w-5 h-5 text-amber-600" />;
      default:
        return <span className="text-white/70 font-bold">{rank}</span>;
    }
  };

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center">
      <div className="absolute inset-0 bg-black bg-opacity-75"></div>
      
      {showConfetti && (
        <div className="absolute inset-0 pointer-events-none">
          {[...Array(30)].map((_, i) => (
            <div
              key={i}
              className="absolute"
              style={{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
                animation: `fall ${2 + Math.random() * 3}s linear infinite`,
                animationDelay: `${Math.random() * 2}s`,
              }}
            >
              <div className={`w-1 h-1 rounded-full ${
                ['bg-yellow-400', 'bg-blue-400', 'bg-green-400', 'bg-red-400', 'bg-purple-400'][Math.floor(Math.random() * 5)]
              }`}></div>
            </div>
          ))}
        </div>
      )}

      {/* Scoreboard card */}
      <div className="relative bg-gradient-to-br from-gray-900 via-gray-800 to-black rounded-2xl shadow-2xl p-8 max-w-4xl w-full mx-4 max-h-[80vh] overflow-hidden">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="flex items-center justify-center mb-4">
            <Trophy className="w-8 h-8 text-yellow-400 mr-3" />
            <h2 className="text-3xl font-bold text-white">
              {getEventTypeName(scoreboardData.eventType)} Event Results
            </h2>
          </div>
          <div className="flex items-center justify-center space-x-6 text-white/80 mb-4">
            <div className="flex items-center space-x-2">
              <Users className="w-4 h-4" />
              <span>{scoreboardData.players.length} Players</span>
            </div>
            <div className="flex items-center space-x-2">
              <Clock className="w-4 h-4" />
              <span>{formatTime(scoreboardData.duration)}</span>
            </div>
          </div>
          {/* Winner indicator */}
          {scoreboardData.players.find(p => p.isWinner) && (
            <div className="bg-gradient-to-r from-yellow-400/20 to-orange-400/20 border border-yellow-400/30 rounded-lg p-3 mb-4">
              <div className="flex items-center justify-center space-x-2">
                <Trophy className="w-5 h-5 text-yellow-400" />
                <span className="text-yellow-400 font-bold text-lg">
                  Winner: {scoreboardData.players.find(p => p.isWinner)?.name}
                </span>
                <Trophy className="w-5 h-5 text-yellow-400" />
              </div>
            </div>
          )}
          {/* Timer */}
          <div className="text-white/70 text-sm">
            Closing in {timeLeft} seconds
          </div>
        </div>

        {/* Players table */}
        <div className="bg-white/5 rounded-xl p-6 mb-6 overflow-y-auto max-h-[50vh]">
          <div className="grid grid-cols-12 gap-4 text-white/80 text-sm font-semibold mb-4 pb-2 border-b border-white/20">
            <div className="col-span-1 text-center">Rank</div>
            <div className="col-span-4">Player</div>
            <div className="col-span-2 text-center">Kills</div>
            <div className="col-span-2 text-center">Time Alive</div>
            <div className="col-span-2 text-center">K/D Ratio</div>
            <div className="col-span-1 text-center">Status</div>
          </div>
          
          {scoreboardData.players.map((player, index) => (
            <div 
              key={player.id}
              className={`grid grid-cols-12 gap-4 items-center py-3 px-2 rounded-lg transition-colors ${
                player.isWinner 
                  ? 'bg-gradient-to-r from-yellow-400/20 to-orange-400/20 border border-yellow-400/30' 
                  : index % 2 === 0 
                    ? 'bg-white/5' 
                    : 'bg-white/10'
              }`}
            >
              <div className="col-span-1 flex justify-center items-center">
                {getRankIcon(player.rank)}
              </div>
              <div className="col-span-4">
                <div className="flex items-center space-x-2">
                  <span className={`font-semibold ${player.isWinner ? 'text-yellow-400' : 'text-white'}`}>
                    {player.name}
                  </span>
                  {player.isWinner && <Trophy className="w-4 h-4 text-yellow-400" />}
                </div>
              </div>
              <div className="col-span-2 text-center">
                <div className="flex items-center justify-center space-x-1">
                  <Target className="w-4 h-4 text-red-400" />
                  <span className="font-bold text-white">{player.kills}</span>
                </div>
              </div>
              <div className="col-span-2 text-center">
                <div className="flex items-center justify-center space-x-1">
                  <Clock className="w-4 h-4 text-blue-400" />
                  <span className="font-bold text-white">{formatTime(player.timeAlive)}</span>
                </div>
              </div>
              <div className="col-span-2 text-center">
                <span className="font-bold text-white">
                  {player.kills > 0 ? player.kills.toFixed(1) : '0.0'}
                </span>
              </div>
              <div className="col-span-1 text-center">
                <span className={`px-2 py-1 rounded-full text-xs font-semibold ${
                  player.isWinner 
                    ? 'bg-yellow-400/20 text-yellow-400' 
                    : 'bg-green-400/20 text-green-400'
                }`}>
                  {player.isWinner ? 'Winner' : 'Alive'}
                </span>
              </div>
            </div>
          ))}
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

export default Scoreboard;
