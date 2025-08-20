import React, { useState, useEffect } from 'react';

interface CountdownProps {
  time: number;
  onComplete: () => void;
}

const Countdown: React.FC<CountdownProps> = ({ time, onComplete }) => {
  const [countdown, setCountdown] = useState(time);

  useEffect(() => {
    if (countdown <= 0) {
      onComplete();
      return;
    }

    const timer = setTimeout(() => {
      setCountdown(countdown - 1);
    }, 1000);

    return () => clearTimeout(timer);
  }, [countdown, onComplete]);

  if (countdown <= 0) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50">
      <div className="text-center">
        <div className="text-8xl font-bold text-white mb-4 animate-pulse">
          {countdown}
        </div>
        <div className="text-2xl text-white font-medium">
          {countdown === 1 ? 'Get Ready!' : 'Starting Soon...'}
        </div>
      </div>
    </div>
  );
};

export default Countdown;
