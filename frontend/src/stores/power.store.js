// VERTEBR — stores/power.store.js
// Auteur : Houssam | Licence : MIT
import { defineStore } from 'pinia';
import { vertebrClient } from '@/services/api/vertebr-client';

export const usePowerStore = defineStore('power', {
  state: () => ({
    status: {
      has_battery:     false,
      battery_percent: 0,
      battery_state:   'Unknown',
      on_battery:      false,
      time_remaining:  null,
      power_profile:   'balanced',
    },
    loading: false,
  }),
  actions: {
    async load() {
      this.loading = true;
      const res = await vertebrClient.call('power:status');
      if (res.status === 'success') this.status = res.data;
      this.loading = false;
    },
    async setProfile(profile) {
      await vertebrClient.call('power:profile', { profile });
      this.status.power_profile = profile;
    },
    async reboot()   { return await vertebrClient.call('power:reboot');   },
    async shutdown() { return await vertebrClient.call('power:shutdown'); },
    async suspend()  { return await vertebrClient.call('power:suspend');  },
  },
});
