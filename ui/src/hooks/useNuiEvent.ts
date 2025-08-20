import { useEffect } from 'react';

/**
 * Hook to listen for NUI events
 * @param action The action to listen for
 * @param handler The handler function
 */
export const useNuiEvent = (action: string, handler: (data: any) => void) => {
  useEffect(() => {
    const eventListener = (event: MessageEvent) => {
      const { data } = event;

      if (data.action === action) {
        handler(data);
      }
    };

    window.addEventListener('message', eventListener);
    return () => window.removeEventListener('message', eventListener);
  }, [action, handler]);
};
