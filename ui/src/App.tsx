import React, { useState } from 'react'
import { X, Plus, Trophy, Settings, Moon, Sun } from 'lucide-react'
import EventList from './components/EventList'
import CreateEvent from './components/CreateEvent'
import EventDetails from './components/EventDetails'


import EventJoinPanel from './components/EventJoinPanel'
import { useNuiEvent } from './hooks/useNuiEvent'
import { fetchNui } from './utils/fetchNui'

interface Event {
  id: string
  type: string
  hostName: string
  hostId: number
  maxPlayers: number
  currentPlayers: number
  reward: number
  rewardType?: string
  rewardData?: any
  config: any
  status?: string
}



interface AppState {
  visible: boolean
  events: Event[]
  currentEvent: Event | null
  showCreateEvent: boolean
  showEventDetails: boolean

  isDarkMode: boolean

  currentPlayerId: number | null
  eventJoinPanel: { event: Event; deadline: number; hasJoined?: boolean } | null
  globalEventJoinPanel: { event: Event; deadline: number; hasJoined?: boolean } | null

}

const App: React.FC = () => {
  const [state, setState] = useState<AppState>({
    visible: false,
    events: [],
    currentEvent: null,
    showCreateEvent: false,
    showEventDetails: false,

    isDarkMode: true,

    currentPlayerId: null,
    eventJoinPanel: null,
    globalEventJoinPanel: null,

  })

  // NUI Event handlers
  useNuiEvent('setVisible', (data: { visible: boolean }) => {
    setState(prev => ({ ...prev, visible: data.visible }))
  })

  useNuiEvent('updateEvents', (data: { events: Event[]; currentPlayerId: number }) => {
    setState(prev => ({ ...prev, events: data.events, currentPlayerId: data.currentPlayerId }))
  })



  useNuiEvent('playerJoined', (data: { eventId: string; playerId: number; playerName: string }) => {
    // Update event participants count
    setState(prev => ({
      ...prev,
      events: prev.events.map(event => 
        event.id === data.eventId 
          ? { ...event, currentPlayers: event.currentPlayers + 1 }
          : event
      )
    }))
  })

  useNuiEvent('playerLeft', (data: { eventId: string; playerId: number }) => {
    // Update event participants count
    setState(prev => ({
      ...prev,
      events: prev.events.map(event => 
        event.id === data.eventId 
          ? { ...event, currentPlayers: Math.max(0, event.currentPlayers - 1) }
          : event
      )
    }))
  })

  useNuiEvent('playerEliminated', (data: { eventId: string; playerId: number; playerName: string }) => {
    console.log(`Player ${data.playerName} eliminated from event ${data.eventId}`)
  })

  const handleClose = () => {
    fetchNui('closeUI')
    setState(prev => ({ ...prev, visible: false }))
  }

  const handleCreateEvent = () => {
    setState(prev => ({ ...prev, showCreateEvent: true }))
  }

  const handleEventClick = (event: Event) => {
    setState(prev => ({ 
      ...prev, 
      currentEvent: event, 
      showEventDetails: true 
    }))
  }

  const handleRefresh = () => {
    fetchNui('refreshEvents')
  }





  const toggleDarkMode = () => {
    setState(prev => ({ ...prev, isDarkMode: !prev.isDarkMode }));
  };



  // Event join panel handlers
  useNuiEvent('showEventJoinPanel', (data: { event: Event; deadline: number; hasJoined?: boolean }) => {
    setState(prev => ({ ...prev, eventJoinPanel: data }));
  });

  useNuiEvent('hideEventJoinPanel', () => {
    setState(prev => ({ ...prev, eventJoinPanel: null }));
  });

  useNuiEvent('updateEventJoinPanel', (data: { hasJoined: boolean }) => {
    setState(prev => ({ 
      ...prev, 
      eventJoinPanel: prev.eventJoinPanel ? { ...prev.eventJoinPanel, hasJoined: data.hasJoined } : null 
    }));
  });

  // Global event join panel handlers
  useNuiEvent('showGlobalEventJoinPanel', (data: { event: Event; deadline: number; hasJoined?: boolean }) => {
    setState(prev => ({ ...prev, globalEventJoinPanel: data }));
  });

  useNuiEvent('hideGlobalEventJoinPanel', () => {
    setState(prev => ({ ...prev, globalEventJoinPanel: null }));
  });

  useNuiEvent('updateGlobalEventJoinPanel', (data: { hasJoined: boolean }) => {
    setState(prev => ({ 
      ...prev, 
      globalEventJoinPanel: prev.globalEventJoinPanel ? { ...prev.globalEventJoinPanel, hasJoined: data.hasJoined } : null 
    }));
  });



  if (!state.visible) return null

  return (
    <div className={`fixed inset-0 ${state.isDarkMode ? 'dark' : ''}`}>
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4">
        <div className={`${state.isDarkMode ? 'bg-gray-900 text-white' : 'bg-white text-gray-900'} rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden`}>
        {/* Header */}
        <div className="bg-gradient-to-r from-primary to-blue-600 text-white p-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Trophy className="w-8 h-8" />
              <div>
                <h1 className="text-2xl font-bold">Event Management System</h1>
                <p className="text-blue-100">Manage and join exciting events</p>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <button
                onClick={toggleDarkMode}
                className="p-2 hover:bg-white hover:bg-opacity-20 rounded-lg transition-colors"
                title={state.isDarkMode ? "Light Mode" : "Dark Mode"}
              >
                {state.isDarkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
              </button>
              <button
                onClick={handleRefresh}
                className="p-2 hover:bg-white hover:bg-opacity-20 rounded-lg transition-colors"
                title="Refresh Events"
              >
                <Settings className="w-5 h-5" />
              </button>
              <button
                onClick={handleClose}
                className="p-2 hover:bg-white hover:bg-opacity-20 rounded-lg transition-colors"
                title="Close"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-6">
          {state.showCreateEvent ? (
            <CreateEvent
              isDarkMode={state.isDarkMode}
              onClose={() => setState(prev => ({ ...prev, showCreateEvent: false }))}
              onCreated={() => {
                setState(prev => ({ ...prev, showCreateEvent: false }))
                handleRefresh()
              }}
            />
          ) : state.showEventDetails && state.currentEvent ? (
            <EventDetails
              event={state.currentEvent}
              currentPlayerId={state.currentPlayerId}
              isDarkMode={state.isDarkMode}
              onClose={() => setState(prev => ({ ...prev, showEventDetails: false, currentEvent: null }))}
              onJoin={() => {
                fetchNui('joinEvent', { eventId: state.currentEvent!.id })
                setState(prev => ({ ...prev, showEventDetails: false, currentEvent: null }))
              }}
              onStart={() => {
                fetchNui('startEvent', { eventId: state.currentEvent!.id })
                setState(prev => ({ ...prev, showEventDetails: false, currentEvent: null }))
              }}
              onStop={() => {
                fetchNui('stopEvent', { eventId: state.currentEvent!.id })
                setState(prev => ({ ...prev, showEventDetails: false, currentEvent: null }))
              }}
            />
          ) : (
            <div className="space-y-6">
              {/* Action Bar */}
              <div className="flex items-center justify-between">
                              <div className="flex items-center space-x-4">
                <h2 className={`text-xl font-semibold ${state.isDarkMode ? 'text-white' : 'text-gray-800'}`}>Active Events</h2>
                <span className="bg-primary text-white px-3 py-1 rounded-full text-sm font-medium">
                  {state.events.length} Events
                </span>
              </div>
                <button
                  onClick={handleCreateEvent}
                  className="bg-primary hover:bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  <span>Create Event</span>
                </button>
              </div>

              {/* Events List */}
              <EventList
                events={state.events}
                isDarkMode={state.isDarkMode}
                onEventClick={handleEventClick}
              />
            </div>
          )}
        </div>
      </div>
    </div>



    

      {/* Event Join Panel */}
      {state.eventJoinPanel && (
        <EventJoinPanel
          event={state.eventJoinPanel.event}
          deadline={state.eventJoinPanel.deadline}
          hasJoined={state.eventJoinPanel.hasJoined}
          onClose={() => {
            fetchNui('declineEvent', { eventId: state.eventJoinPanel!.event.id });
            setState(prev => ({ ...prev, eventJoinPanel: null }));
          }}
          onJoin={() => {
            if (state.eventJoinPanel!.hasJoined) {
              fetchNui('leaveEvent', { eventId: state.eventJoinPanel!.event.id });
            } else {
              fetchNui('joinEvent', { eventId: state.eventJoinPanel!.event.id });
            }
          }}
        />
      )}



    </div>
  )
}

export default App
