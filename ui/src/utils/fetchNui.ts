/**
 * Sends a message to the NUI callback
 * @param eventName The event name to send
 * @param data The data to send with the event
 */
export const fetchNui = async <T = any>(eventName: string, data?: any): Promise<T> => {
  const options = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  };

  const resourceName = (window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'peleg-events';

  const resp = await fetch(`https://${resourceName}/${eventName}`, options);
  const respFormatted = await resp.json();

  return respFormatted;
};
