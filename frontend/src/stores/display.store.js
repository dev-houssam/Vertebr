// VERTEBR — stores/display.store.js
// Auteur : Houssam | Licence : MIT
import { defineStore } from 'pinia';
import { vertebrClient } from '@/services/api/vertebr-client';

export const useDisplayStore = defineStore('display', {
  state: () => ({
    displays: [],
    loading:  false,
  }),
  actions: {
    async load() {
      this.loading = true;
      const res = await vertebrClient.call('display:list');
      if (res.status === 'success') this.displays = res.data;
      this.loading = false;
    },
    async setMode(display, resolution, refresh) {
      return await vertebrClient.call('display:mode', { display, resolution, refresh });
    },
    async setRotation(display, rotation) {
      return await vertebrClient.call('display:rotation', { display, rotation });
    },
  },
});
