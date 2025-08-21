import React, { useState } from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import GlobalNotifications from './GlobalNotifications.tsx'
import GlobalEventJoinPanel from './GlobalEventJoinPanel.tsx'
import Countdown from './components/Countdown.tsx'
import Scoreboard from './components/Scoreboard.tsx'
import WinnerUI from './components/WinnerUI.tsx'
import KillFeed from './components/KillFeed.tsx'
import KillsCounter from './components/KillsCounter.tsx'
import { useNuiEvent } from './hooks/useNuiEvent'
import './index.css'

const GlobalCountdown: React.FC = () => {
  const [countdown, setCountdown] = useState<{ active: boolean; time: number; eventId: string } | null>(null);

  useNuiEvent('showCountdown', (data: { eventId: string; countdown: number }) => {
    setCountdown({ active: true, time: data.countdown, eventId: data.eventId });
    
    // Hide join panels when countdown starts
    const event = new CustomEvent('hideJoinPanels');
    window.dispatchEvent(event);
  });

  const handleCountdownComplete = () => {
    setCountdown(null);
  };

  if (!countdown?.active) return null;

  return (
    <Countdown
      time={countdown.time}
      onComplete={handleCountdownComplete}
    />
  );
};

const GlobalScoreboard: React.FC = () => {
  const [scoreboardData, setScoreboardData] = useState<{ eventId: string; eventType: string; players: Array<{ id: number; name: string; kills: number; timeAlive: number; rank: number; isWinner?: boolean }>; duration: number } | null>(null);

  useNuiEvent('showScoreboard', (data: { eventId: string; eventType: string; players: Array<{ id: number; name: string; kills: number; timeAlive: number; rank: number; isWinner?: boolean }>; duration: number }) => {
    setScoreboardData(data);
  });

  const handleClose = () => {
    setScoreboardData(null);
  };

  if (!scoreboardData) return null;

  return (
    <Scoreboard
      scoreboardData={scoreboardData}
      onClose={handleClose}
    />
  );
};

const GlobalKillsCounter: React.FC = () => {
  const [killsData, setKillsData] = useState<{ kills: number; isVisible: boolean }>({ kills: 0, isVisible: false });

  useNuiEvent('updateKillsCounter', (data: { kills: number; isVisible: boolean }) => {
    setKillsData(data);
  });

  useNuiEvent('hideKillsCounter', () => {
    setKillsData(prev => ({ ...prev, isVisible: false }));
  });

  return (
    <KillsCounter
      kills={killsData.kills}
      isVisible={killsData.isVisible}
    />
  );
};

const GlobalWinnerUI: React.FC = () => {
  const [winnerData, setWinnerData] = useState<{ eventId: string; eventType: string; winnerName: string; winnerId: number; reward: { type: string; data: any }; participants: number } | null>(null);

  useNuiEvent('showWinnerUI', (data: { eventId: string; eventType: string; winnerName: string; winnerId: number; reward: { type: string; data: any }; participants: number }) => {
    setWinnerData(data);
  });

  const handleClose = () => {
    setWinnerData(null);
  };

  if (!winnerData) return null;

  return (
    <WinnerUI
      winnerData={winnerData}
      onClose={handleClose}
    />
  );
};

const GlobalKillFeed: React.FC = () => {
  const [killFeed, setKillFeed] = useState<Array<{ id: string; killer: string; victim: string; eventType: string; timestamp: number }>>([]);

  useNuiEvent('addKillFeed', (data: { killer: string; victim: string; eventType: string }) => {
    const newKill = {
      id: Date.now().toString(),
      killer: data.killer,
      victim: data.victim,
      eventType: data.eventType,
      timestamp: Date.now()
    };
    
    setKillFeed(prev => [...prev.slice(-4), newKill]); 
    
    setTimeout(() => {
      setKillFeed(prev => prev.filter(kill => kill.id !== newKill.id));
    }, 5000);
  });

  if (killFeed.length === 0) return null;

  return (
    <KillFeed kills={killFeed} />
  );
};

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
    <GlobalNotifications />
    <GlobalEventJoinPanel />
    <GlobalCountdown />
    <GlobalScoreboard />
    <GlobalWinnerUI />
    <GlobalKillsCounter />
    <GlobalKillFeed />
  </React.StrictMode>,
)
