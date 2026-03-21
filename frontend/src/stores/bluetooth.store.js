// VERTEBR — stores/bluetooth.store.js
import { defineStore } from 'pinia';
import { vertebrClient } from '@/services/api/vertebr-client';

export const useBluetoothStore = defineStore('bluetooth', {
  state: () => ({ devices: [], status: { enabled: false, discoverable: false, adapter: '' }, loading: false, error: null }),
  getters: {
    connectedDevices: (s) => s.devices.filter(d => d.connected),
    pairedDevices:    (s) => s.devices.filter(d => d.paired),
  },
  actions: {
    async load() {
      this.loading = true;
      try {
        const [devRes, statRes] = await Promise.all([
          vertebrClient.call('bluetooth:list'),
          vertebrClient.call('bluetooth:status'),
        ]);
        if (devRes.status  === 'success') this.devices = devRes.data;
        if (statRes.status === 'success') this.status  = statRes.data;
      } catch (e) { this.error = e.message; }
      finally { this.loading = false; }
    },
    async setPower(enabled)    { await vertebrClient.call('bluetooth:power',      { enabled });          await this.load(); },
    async connect(address)     { return await vertebrClient.call('bluetooth:connect',    { address }); },
    async disconnect(address)  { return await vertebrClient.call('bluetooth:disconnect', { address }); },
    async pair(address)        { return await vertebrClient.call('bluetooth:pair',       { address }); },
    async remove(address)      { await vertebrClient.call('bluetooth:remove', { address }); await this.load(); },
  },
});
