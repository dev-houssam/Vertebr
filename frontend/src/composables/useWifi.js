// VERTEBR — composables/useWifi.js
// Hook réutilisable Wi-Fi
// Auteur : Houssam | Licence : MIT
import { computed } from 'vue';
import { storeToRefs } from 'pinia';
import { useWifiStore } from '@/stores/wifi.store.js';

export function useWifi() {
  const store = useWifiStore();
  const { networks, status, loading, error, connectedNetwork, availableNetworks, isConnected } = storeToRefs(store);

  return {
    // State
    networks, status, loading, error,
    // Getters
    connectedNetwork, availableNetworks, isConnected,
    // Actions
    load:           () => store.load(),
    connect:        (ssid, pwd)  => store.connect(ssid, pwd),
    disconnect:     ()           => store.disconnect(),
    setEnabled:     (v)          => store.setEnabled(v),
    setAirplaneMode:(v)          => store.setAirplaneMode(v),
    forget:         (ssid)       => store.forget(ssid),
  };
}
