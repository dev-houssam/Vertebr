// VERTEBR — stores/wifi.store.js
import { defineStore } from 'pinia';
import { vertebrClient } from '@/services/api/vertebr-client';

export const useWifiStore = defineStore('wifi', {
  state: () => ({
    networks:     [],
    status:       { enabled: true, airplane_mode: false, connected_to: null },
    loading:      false,
    error:        null,
    lastRefresh:  null,
  }),
  getters: {
    connectedNetwork: (s) => s.networks.find(n => n.in_use),
    availableNetworks: (s) => s.networks.filter(n => !n.in_use),
    isConnected: (s) => !!s.status.connected_to,
  },
  actions: {
    async load() {
      this.loading = true; this.error = null;
      try {
        const [netRes, statRes] = await Promise.all([
          vertebrClient.call('wifi:list'),
          vertebrClient.call('wifi:status'),
        ]);
        if (netRes.status  === 'success') this.networks = netRes.data;
        if (statRes.status === 'success') this.status   = statRes.data;
        this.lastRefresh = new Date();
      } catch (e) { this.error = e.message; }
      finally { this.loading = false; }
    },
    async connect(ssid, password = null) {
      const res = await vertebrClient.call('wifi:connect', { ssid, password });
      if (res.status === 'success') await this.load();
      return res;
    },
    async disconnect() {
      const res = await vertebrClient.call('wifi:disconnect');
      if (res.status === 'success') await this.load();
      return res;
    },
    async setEnabled(enabled) {
      await vertebrClient.call('wifi:enabled', { enabled });
      await this.load();
    },
    async setAirplaneMode(enabled) {
      await vertebrClient.call('wifi:airplane', { enabled });
      this.status.airplane_mode = enabled;
    },
    async forget(ssid) {
      const res = await vertebrClient.call('wifi:forget', { ssid });
      if (res.status === 'success') await this.load();
      return res;
    },
  },
});
