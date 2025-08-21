# Peleg Events System

A comprehensive FiveM standalone event system with three exciting event types: Car Sumo, Redzone, and Party events. Features a modern React TypeScript UI with Tailwind CSS.

## Preview
<div align="center">

<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/41702157-d1cc-48b8-8d9e-2277d72f2d61" width="350"/></td>
    <td><img src="https://github.com/user-attachments/assets/0c1dcf6a-b613-4e41-9935-abfbaf3f1440" width="350"/></td>
    <td><img src="https://github.com/user-attachments/assets/b285db21-e5d8-4ac0-9679-c5710bd056ee" width="350"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/ded3b781-e833-4e2b-8b79-5f53f6f24e21" width="350"/></td>
    <td><img src="https://github.com/user-attachments/assets/028dbbdf-ce04-46f3-9d07-60dd2e3a4bcc" width="350"/></td>
    <td><img src="https://github.com/user-attachments/assets/5f587f42-7f71-4ae2-a68b-bf1aca5f1ceb" width="350"/></td>
  </tr>
  <tr>
    <td colspan="3" align="center">
      <img src="https://github.com/user-attachments/assets/f0313594-eaf6-4f34-bda4-9d084062a9b5" width="600"/>
    </td>
  </tr>
</table>

</div>

## Features

### Event Types

1. **Car Sumo**
   - Players are teleported to a sky ring in vehicles
   - Last player to stay on the ring wins
   - Falling below the ring results in elimination
   - Vehicles explode when players are eliminated
   - Spectator mode for eliminated players

2. **Redzone**
   - Last man standing in a designated zone
   - Players spawn in different locations within the zone
   - Infinite ammo for all weapons
   - Stay within the redzone boundaries
   - Instant respawn and spectator mode for eliminated players

3. **Party**
   - All participants teleported to the host's location
   - Everyone receives a reward upon completion
   - Simple social gathering event

### System Features

- **Authorization System**: Only authorized licenses can access the event management
- **Framework Detection**: Auto-detects ESX, QBCore, or standalone frameworks
- **Modern UI**: React TypeScript interface with Tailwind CSS
- **Real-time Updates**: Live participant tracking and event status
- **Statistics Tracking**: Player event history and statistics
- **Responsive Design**: Works on all screen sizes

## Installation

1. **Download the Resource**
   ```bash
   # Place the resource in your server's resources folder
   # Example: resources/[peleg]/peleg-events/
   ```

2. **Configure Authorization**
   Edit `shared/config.lua` and add your authorized licenses:
   ```lua
   Config.AuthorizedLicenses = {
       "license:your_license_here",
       "license:another_license_here"
   }
   ```

3. **Configure Event Locations**
   Update spawn locations and zone settings in `shared/config.lua`:
   ```lua
   Config.Events = {
       CarSumo = {
           spawnLocation = vector3(0.0, 0.0, 1000.0), -- Sky ring location
           ringRadius = 50.0,
           fallHeight = 800.0
       },
       Redzone = {
           spawnLocations = {
               vector3(100.0, 100.0, 20.0),
               -- Add more spawn locations...
           },
           zoneCenter = vector3(450.0, 100.0, 20.0),
           zoneRadius = 200.0
       }
   }
   ```

4. **Build the UI**
   ```bash
   cd ui
   npm install
   npm run build
   ```

5. **Add to server.cfg**
   ```cfg
   ensure peleg-events
   ```

## Usage

### Commands

- `/events` - Open the event management UI (authorized users only)

### UI Features

1. **Create Events**
   - Select event type (Car Sumo, Redzone, Party)
   - Configure maximum players
   - Set event parameters

2. **Join Events**
   - View active events
   - See participant count and rewards
   - Join with one click

3. **Event Management**
   - Host can start events
   - Real-time participant tracking
   - Event status monitoring

### Event Flow

1. **Event Creation**: Authorized user creates an event
2. **Player Joining**: Players can join the event
3. **Event Start**: Host starts the event when ready
4. **Countdown**: Players see countdown before event begins
5. **Event Execution**: Event-specific gameplay
6. **Winner Declaration**: Winner receives reward
7. **Cleanup**: All players returned to original positions

## Configuration

### Event Settings

Each event type has configurable settings in `shared/config.lua`:

```lua
Config.Events = {
    CarSumo = {
        name = "Car Sumo",
        description = "Fight to the death in cars above the sky!",
        maxPlayers = 16,
        minPlayers = 2,
        reward = 5000,
        spawnLocation = vector3(0.0, 0.0, 1000.0),
        ringRadius = 50.0,
        fallHeight = 800.0,
        countdownDuration = 10
    }
}
```

### Framework Integration

The system automatically detects and integrates with:
- ESX Framework
- QBCore Framework
- Standalone (no framework)

### Customization

- **UI Colors**: Modify colors in `shared/config.lua`
- **Event Types**: Add new event types by extending the system
- **Spawn Locations**: Configure custom spawn points for each event
- **Rewards**: Adjust reward amounts per event type

## Development

### Building the UI

```bash
cd ui
npm install
npm run dev    # Development mode
npm run build  # Production build
```

### File Structure

```
peleg-events/
├── fxmanifest.lua
├── shared/
│   ├── config.lua
│   └── utils.lua
├── server/
│   ├── main.lua
│   ├── database.lua
│   └── events/
│       ├── carSumo.lua
│       ├── redzone.lua
│       └── party.lua
├── client/
│   ├── main.lua
│   ├── ui.lua
│   └── events/
│       ├── carSumo.lua
│       ├── redzone.lua
│       └── party.lua
└── ui/
    ├── src/
    │   ├── components/
    │   ├── hooks/
    │   ├── utils/
    │   └── App.tsx
    ├── package.json
    └── README.md
```

## API Reference

### Server Exports

```lua
-- Get all active events
local events = exports['peleg-events']:getActiveEvents()

-- Check if player is authorized
local authorized = exports['peleg-events']:isPlayerAuthorized(playerId)

-- Create an event
local eventId = exports['peleg-events']:createEvent(eventType, hostId, maxPlayers)

-- Finish an event
exports['peleg-events']:finishEvent(eventId, winnerId)
```

### Client Exports

```lua
-- Show/hide UI
exports['peleg-events']:setUIVisible(enabled)

-- Update events list
exports['peleg-events']:updateEventsList(events)

-- Show countdown
exports['peleg-events']:showEventCountdown(eventId, countdown)
```

## Troubleshooting

### Common Issues

1. **UI Not Loading**
   - Ensure the UI is built (`npm run build` in ui folder)
   - Check file paths in fxmanifest.lua

2. **Events Not Working**
   - Verify framework detection in shared/utils.lua
   - Check authorization licenses in config.lua

3. **Players Not Teleporting**
   - Verify spawn locations are valid coordinates
   - Check if players have proper permissions

### Debug Mode

Enable debug logging by adding to config.lua:
```lua
Config.Debug = true
```

## Support

For support and updates, please refer to the documentation or contact the developer.

## License

This resource is provided as-is for FiveM server use.
