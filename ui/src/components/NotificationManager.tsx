import React, { } from 'react';
import Notification from './Notification';

interface NotificationItem {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
  duration?: number;
}

interface NotificationManagerProps {
  notifications: NotificationItem[];
  onRemoveNotification: (id: string) => void;
}

const NotificationManager: React.FC<NotificationManagerProps> = ({ 
  notifications, 
  onRemoveNotification 
}) => {
  return (
    <div className="notification-container">
      {notifications.map((notification) => (
        <Notification
          key={notification.id}
          id={notification.id}
          type={notification.type}
          message={notification.message}
          duration={notification.duration}
          onClose={onRemoveNotification}
        />
      ))}
    </div>
  );
};

export default NotificationManager;
