import React, { useState } from 'react';
import { X, Car, Target, PartyPopper, Users, DollarSign, Package, Gift, ArrowLeft, ArrowRight, Coins, Box, Car as CarIcon } from 'lucide-react';
import { fetchNui } from '../utils/fetchNui';

interface CreateEventProps {
  isDarkMode?: boolean;
  onClose: () => void;
  onCreated: () => void;
}

const CreateEvent: React.FC<CreateEventProps> = ({ isDarkMode = false, onClose, onCreated }) => {
  const [currentStep, setCurrentStep] = useState<number>(1);
  const [eventType, setEventType] = useState<string>('');
  const [maxPlayers, setMaxPlayers] = useState<number>(16);
  
  // Reward settings
  const [rewardType, setRewardType] = useState<string>('money');
  const [rewardAmount, setRewardAmount] = useState<string>('5000');
  const [rewardItem, setRewardItem] = useState<string>('');
  const [rewardVehicle, setRewardVehicle] = useState<string>('');
  
  // Custom settings
  const [customVehicles, setCustomVehicles] = useState<string>('');
  const [customWeapons, setCustomWeapons] = useState<string>('');
  const [zoneBaseSize, setZoneBaseSize] = useState<number>(200);
  const [zoneChangeSpeed, setZoneChangeSpeed] = useState<number>(1.0);
  const [partyLocation, setPartyLocation] = useState<string>('0.0, 0.0, 0.0, 0.0');

  const eventTypes = [
    {
      id: 'CarSumo',
      name: 'Car Sumo',
      description: 'Fight to the death in cars above the sky!',
      icon: <Car className="w-6 h-6" />,
      maxPlayers: 16,
      reward: 5000
    },
    {
      id: 'Redzone',
      name: 'Redzone',
      description: 'Last man standing in the redzone!',
      icon: <Target className="w-6 h-6" />,
      maxPlayers: 32,
      reward: 10000
    },
    {
      id: 'Party',
      name: 'Party',
      description: 'Join the party at the host\'s location!',
      icon: <PartyPopper className="w-6 h-6" />,
      maxPlayers: 50,
      reward: 1000
    }
  ];

  const selectedEvent = eventTypes.find(e => e.id === eventType);

  const nextStep = () => {
    if (currentStep < 4) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleCreate = async () => {
    try {
      // Prepare reward data
      let rewardData = {};
      if (rewardType === 'money') {
        rewardData = { amount: parseInt(rewardAmount) || 0 };
      } else if (rewardType === 'item') {
        rewardData = { item: rewardItem, amount: parseInt(rewardAmount) || 1 };
      } else if (rewardType === 'vehicle') {
        rewardData = { vehicle: rewardVehicle };
      }
      
      // Prepare custom settings
      const customSettings: any = {};
      if (eventType === 'CarSumo' && customVehicles) {
        customSettings.vehicles = customVehicles.split(',').map(v => v.trim()).filter(v => v);
      }
      if (eventType === 'Redzone') {
        if (customWeapons) {
          customSettings.weapons = customWeapons.split(',').map(w => w.trim()).filter(w => w);
        }
        customSettings.zoneBaseSize = zoneBaseSize;
        customSettings.zoneChangeSpeed = zoneChangeSpeed;
      }
      if (eventType === 'Party') {
        customSettings.location = partyLocation;
      }
      
      await fetchNui('createEvent', { 
        eventType, 
        maxPlayers, 
        rewardType, 
        rewardData, 
        customSettings 
      });
      onCreated();
    } catch (error) {
      console.error('Failed to create event:', error);
    }
  };

  const canProceed = () => {
    switch (currentStep) {
      case 1: return eventType !== '';
      case 2: return maxPlayers >= 2;
      case 3: return rewardType !== '' && (
        rewardType === 'money' ? rewardAmount !== '' :
        rewardType === 'item' ? rewardItem !== '' && rewardAmount !== '' :
        rewardType === 'vehicle' ? rewardVehicle !== '' : false
      );
      case 4: return true; // Optional step
      default: return false;
    }
  };

  return (
    <div className="h-full flex flex-col p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <h2 className={`text-2xl font-bold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>Create New Event</h2>
        <button
          onClick={onClose}
          className={`p-2 rounded-lg transition-colors ${isDarkMode ? 'hover:bg-gray-700' : 'hover:bg-gray-100'}`}
        >
          <X className="w-5 h-5" />
        </button>
      </div>

      {/* Progress Bar */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <span className={`text-sm font-medium ${isDarkMode ? 'text-gray-300' : 'text-gray-600'}`}>
            Step {currentStep} of 4
          </span>
          <span className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
            {currentStep === 1 && 'Choose Event Type'}
            {currentStep === 2 && 'Set Player Count'}
            {currentStep === 3 && 'Configure Reward'}
            {currentStep === 4 && 'Custom Settings'}
          </span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2 dark:bg-gray-700">
          <div 
            className="bg-blue-600 h-2 rounded-full transition-all duration-300" 
            style={{ width: `${(currentStep / 4) * 100}%` }}
          ></div>
        </div>
      </div>

      {/* Step Content */}
      <div className="flex-1 flex items-center justify-center">
        {currentStep === 1 && (
          <div className="w-full max-w-2xl">
            <h3 className={`text-xl font-semibold mb-6 text-center ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
              What type of event do you want to create?
            </h3>
            <div className="grid gap-4 md:grid-cols-3">
              {eventTypes.map((type) => (
                <div
                  key={type.id}
                  onClick={() => {
                    setEventType(type.id);
                    setMaxPlayers(type.maxPlayers);
                  }}
                  className={`p-6 border-2 rounded-lg cursor-pointer transition-all hover:shadow-lg ${
                    eventType === type.id
                      ? `border-blue-500 bg-blue-50 dark:bg-blue-900/20`
                      : `${isDarkMode ? 'border-gray-600 hover:border-gray-500 bg-gray-800' : 'border-gray-200 hover:border-gray-300 bg-white'}`
                  }`}
                >
                  <div className="flex flex-col items-center text-center">
                    <div className={`p-3 rounded-lg mb-4 ${eventType === type.id ? 'bg-blue-100 dark:bg-blue-800' : 'bg-gray-100 dark:bg-gray-600'}`}>
                      {type.icon}
                    </div>
                    <h4 className={`text-lg font-semibold mb-2 ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>{type.name}</h4>
                    <p className={`text-sm mb-4 ${isDarkMode ? 'text-gray-300' : 'text-gray-600'}`}>{type.description}</p>
                    <div className="flex items-center justify-between w-full text-sm">
                      <div className="flex items-center space-x-1">
                        <Users className="w-4 h-4 text-gray-400" />
                        <span className={isDarkMode ? 'text-gray-300' : 'text-gray-600'}>Max {type.maxPlayers}</span>
                      </div>
                      <div className="flex items-center space-x-1">
                        <DollarSign className="w-4 h-4 text-gray-400" />
                        <span className={isDarkMode ? 'text-gray-300' : 'text-gray-600'}>${(type.reward || 0).toLocaleString()}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {currentStep === 2 && (
          <div className="w-full max-w-md">
            <h3 className={`text-xl font-semibold mb-6 text-center ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
              How many players can join?
            </h3>
            <div className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'} rounded-lg p-8 border ${isDarkMode ? 'border-gray-700' : 'border-gray-200'}`}>
              <div className="text-center mb-6">
                <span className={`text-4xl font-bold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>{maxPlayers}</span>
                <p className={`text-sm ${isDarkMode ? 'text-gray-300' : 'text-gray-600'}`}>Maximum Players</p>
              </div>
              <div className="space-y-4">
                <input
                  type="range"
                  min={Math.max(2, selectedEvent?.maxPlayers ? selectedEvent.maxPlayers / 2 : 8)}
                  max={selectedEvent?.maxPlayers || 16}
                  value={maxPlayers}
                  onChange={(e) => setMaxPlayers(parseInt(e.target.value))}
                  className="w-full h-3 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700"
                />
                <div className="flex justify-between text-sm">
                  <span className={isDarkMode ? 'text-gray-300' : 'text-gray-600'}>2</span>
                  <span className={isDarkMode ? 'text-gray-300' : 'text-gray-600'}>{selectedEvent?.maxPlayers || 16}</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {currentStep === 3 && (
          <div className="w-full max-w-2xl">
            <h3 className={`text-xl font-semibold mb-6 text-center ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
              What should the winner receive?
            </h3>
            <div className="space-y-6">
              {/* Reward Type Selection */}
              <div className="grid gap-4 md:grid-cols-3">
                {[
                  { id: 'money', name: 'Money', icon: <DollarSign className="w-6 h-6" />, desc: 'Cash reward' },
                  { id: 'item', name: 'Item', icon: <Package className="w-6 h-6" />, desc: 'Game item' },
                  { id: 'vehicle', name: 'Vehicle', icon: <Gift className="w-6 h-6" />, desc: 'Car to garage' }
                ].map((type) => (
                  <button
                    key={type.id}
                    onClick={() => setRewardType(type.id)}
                    className={`p-6 border-2 rounded-lg transition-all text-center ${
                      rewardType === type.id
                        ? `border-blue-500 bg-blue-50 dark:bg-blue-900/20`
                        : `${isDarkMode ? 'border-gray-600 hover:border-gray-500 bg-gray-800' : 'border-gray-200 hover:border-gray-300 bg-white'}`
                    }`}
                  >
                    <div className={`inline-flex items-center justify-center w-12 h-12 rounded-lg mb-3 ${
                      rewardType === type.id ? 'bg-blue-100 dark:bg-blue-800' : 'bg-gray-100 dark:bg-gray-600'
                    }`}>
                      {type.icon}
                    </div>
                    <div className={`font-semibold mb-1 ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>{type.name}</div>
                    <div className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>{type.desc}</div>
                  </button>
                ))}
              </div>

              {/* Reward Details */}
              {rewardType && (
                <div className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'} rounded-lg p-6 border ${isDarkMode ? 'border-gray-700' : 'border-gray-200'}`}>
                  {rewardType === 'money' && (
                    <div className="space-y-4">
                      <label className={`block text-lg font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                        <div className="flex items-center space-x-2">
                          <Coins className="w-5 h-5" />
                          <span>Amount of money</span>
                        </div>
                      </label>
                      <input
                        type="number"
                        value={rewardAmount}
                        onChange={(e) => setRewardAmount(e.target.value)}
                        placeholder="5000"
                        className={`w-full px-4 py-3 text-lg border rounded-lg [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none ${isDarkMode ? 'bg-gray-700 border-gray-600 text-white' : 'bg-white border-gray-300'}`}
                      />
                    </div>
                  )}
                  
                  {rewardType === 'item' && (
                    <div className="space-y-4">
                      <label className={`block text-lg font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                        <div className="flex items-center space-x-2">
                          <Box className="w-5 h-5" />
                          <span>Item details</span>
                        </div>
                      </label>
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className={`block text-sm font-medium mb-2 ${isDarkMode ? 'text-gray-300' : 'text-gray-600'}`}>Item Name</label>
                          <input
                            type="text"
                            value={rewardItem}
                            onChange={(e) => setRewardItem(e.target.value)}
                            placeholder="weapon_pistol"
                            className={`w-full px-4 py-3 border rounded-lg ${isDarkMode ? 'bg-gray-700 border-gray-600 text-white' : 'bg-white border-gray-300'}`}
                          />
                        </div>
                        <div>
                          <label className={`block text-sm font-medium mb-2 ${isDarkMode ? 'text-gray-300' : 'text-gray-600'}`}>Quantity</label>
                          <input
                            type="number"
                            value={rewardAmount}
                            onChange={(e) => setRewardAmount(e.target.value)}
                            placeholder="1"
                            className={`w-full px-4 py-3 border rounded-lg [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none ${isDarkMode ? 'bg-gray-700 border-gray-600 text-white' : 'bg-white border-gray-300'}`}
                          />
                        </div>
                      </div>
                    </div>
                  )}
                  
                  {rewardType === 'vehicle' && (
                    <div className="space-y-4">
                      <label className={`block text-lg font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                        <div className="flex items-center space-x-2">
                          <CarIcon className="w-5 h-5" />
                          <span>Vehicle details</span>
                        </div>
                      </label>
                      <input
                        type="text"
                        value={rewardVehicle}
                        onChange={(e) => setRewardVehicle(e.target.value)}
                        placeholder="adder"
                        className={`w-full px-4 py-3 text-lg border rounded-lg ${isDarkMode ? 'bg-gray-700 border-gray-600 text-white' : 'bg-white border-gray-300'}`}
                      />
                      <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                        Enter the vehicle model name (e.g., adder, zentorno, t20)
                      </p>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        )}

        {currentStep === 4 && (
          <div className="w-full max-w-md">
            <h3 className={`text-xl font-semibold mb-6 text-center ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
              Custom Settings (Optional)
            </h3>
            <div className={`${isDarkMode ? 'bg-gray-800' : 'bg-white'} rounded-lg p-6 border ${isDarkMode ? 'border-gray-700' : 'border-gray-200'}`}>
              {eventType === 'CarSumo' && (
                <div className="space-y-4">
                  <label className={`block text-lg font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                    <div className="flex items-center space-x-2">
                      <Car className="w-5 h-5" />
                      <span>Custom Vehicles</span>
                    </div>
                  </label>
                  <input
                    type="text"
                    value={customVehicles}
                    onChange={(e) => setCustomVehicles(e.target.value)}
                    placeholder="adder, zentorno, t20, osiris"
                    className={`w-full px-4 py-3 border rounded-lg ${isDarkMode ? 'bg-gray-700 border-gray-600 text-white' : 'bg-white border-gray-300'}`}
                  />
                  <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                    Separate vehicle names with commas. Leave empty to use default vehicles.
                  </p>
                </div>
              )}
              
              {eventType === 'Redzone' && (
                <div className="space-y-6">
                  <div className="space-y-4">
                    <label className={`block text-lg font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                      <div className="flex items-center space-x-2">
                        <Target className="w-5 h-5" />
                        <span>Custom Weapons</span>
                      </div>
                    </label>
                    <input
                      type="text"
                      value={customWeapons}
                      onChange={(e) => setCustomWeapons(e.target.value)}
                      placeholder="WEAPON_PISTOL, WEAPON_SMG, WEAPON_CARBINERIFLE"
                      className={`w-full px-4 py-3 border rounded-lg ${isDarkMode ? 'bg-gray-700 border-gray-600 text-white' : 'bg-white border-gray-300'}`}
                    />
                    <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                      Separate weapon names with commas. Leave empty to use default weapons.
                    </p>
                  </div>
                  
                  <div className="space-y-4">
                    <label className={`block text-lg font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                      <div className="flex items-center space-x-2">
                        <Target className="w-5 h-5" />
                        <span>Zone Base Size</span>
                      </div>
                    </label>
                    <div className="flex items-center space-x-4">
                      <input
                        type="range"
                        min="50"
                        max="500"
                        value={zoneBaseSize}
                        onChange={(e) => setZoneBaseSize(parseInt(e.target.value))}
                        className="flex-1 h-3 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700"
                      />
                      <span className={`text-lg font-semibold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                        {zoneBaseSize}m
                      </span>
                    </div>
                    <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                      Initial size of the redzone area.
                    </p>
                  </div>
                  
                  <div className="space-y-4">
                    <label className={`block text-lg font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                      <div className="flex items-center space-x-2">
                        <Target className="w-5 h-5" />
                        <span>Zone Shrink Speed</span>
                      </div>
                    </label>
                    <div className="flex items-center space-x-4">
                      <input
                        type="range"
                        min="0.1"
                        max="5.0"
                        step="0.1"
                        value={zoneChangeSpeed}
                        onChange={(e) => setZoneChangeSpeed(parseFloat(e.target.value))}
                        className="flex-1 h-3 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700"
                      />
                      <span className={`text-lg font-semibold ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                        {zoneChangeSpeed}m/s
                      </span>
                    </div>
                    <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                      How fast the zone shrinks per second.
                    </p>
                  </div>
                </div>
              )}

              {eventType === 'Party' && (
                <div className="space-y-4">
                  <label className={`block text-lg font-medium ${isDarkMode ? 'text-white' : 'text-gray-900'}`}>
                    <div className="flex items-center space-x-2">
                      <PartyPopper className="w-5 h-5" />
                      <span>Party Location</span>
                    </div>
                  </label>
                  <input
                    type="text"
                    value={partyLocation}
                    onChange={(e) => setPartyLocation(e.target.value)}
                    placeholder="0.0, 0.0, 0.0, 0.0"
                    className={`w-full px-4 py-3 border rounded-lg ${isDarkMode ? 'bg-gray-700 border-gray-600 text-white' : 'bg-white border-gray-300'}`}
                  />
                  <p className={`text-sm ${isDarkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                    Enter the party location as vector4 (x, y, z, heading). Use your current position: {partyLocation}
                  </p>
                  <button
                    onClick={() => {
                      fetchNui('getCurrentPosition', {}).then((pos: any) => {
                        if (pos && pos.x !== undefined) {
                          setPartyLocation(`${pos.x.toFixed(1)}, ${pos.y.toFixed(1)}, ${pos.z.toFixed(1)}, ${pos.heading.toFixed(1)}`);
                        }
                      });
                    }}
                    className={`px-4 py-2 rounded-lg transition-colors ${isDarkMode ? 'bg-blue-600 hover:bg-blue-700 text-white' : 'bg-blue-600 hover:bg-blue-700 text-white'}`}
                  >
                    Use Current Position
                  </button>
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Navigation */}
      <div className="flex items-center justify-between mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
        <button
          onClick={prevStep}
          disabled={currentStep === 1}
          className={`flex items-center space-x-2 px-4 py-2 border rounded-lg transition-colors ${
            currentStep === 1
              ? 'border-gray-300 text-gray-400 cursor-not-allowed'
              : `${isDarkMode ? 'border-gray-600 text-gray-300 hover:bg-gray-700' : 'border-gray-300 text-gray-700 hover:bg-gray-50'}`
          }`}
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Previous</span>
        </button>

        <div className="flex items-center space-x-3">
          <button
            onClick={onClose}
            className={`px-4 py-2 border rounded-lg transition-colors ${isDarkMode ? 'border-gray-600 text-gray-300 hover:bg-gray-700' : 'border-gray-300 text-gray-700 hover:bg-gray-50'}`}
          >
            Cancel
          </button>
          
          {currentStep < 4 ? (
            <button
              onClick={nextStep}
              disabled={!canProceed()}
              className={`flex items-center space-x-2 px-6 py-2 rounded-lg transition-colors ${
                canProceed()
                  ? 'bg-blue-600 hover:bg-blue-700 text-white'
                  : 'bg-gray-300 text-gray-500 cursor-not-allowed'
              }`}
            >
              <span>Next</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          ) : (
            <button
              onClick={handleCreate}
              disabled={!canProceed()}
              className={`px-6 py-2 rounded-lg transition-colors ${
                canProceed()
                  ? 'bg-green-600 hover:bg-green-700 text-white'
                  : 'bg-gray-300 text-gray-500 cursor-not-allowed'
              }`}
            >
              Create Event
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default CreateEvent;
