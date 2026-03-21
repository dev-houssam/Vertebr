// VERTEBR — stores/caps.store.js
// Auteur : Houssam | Licence : MIT
import { defineStore } from 'pinia';
import { vertebrClient } from '@/services/api/vertebr-client';

export const useCapsStore = defineStore('caps', {
  state: () => ({
    capabilities: [],
    loading:      false,
    error:        null,
  }),
  actions: {
    async load() {
      this.loading = true;
      const res = await vertebrClient.call('caps:list');
      if (res.status === 'success') this.capabilities = res.data;
      this.loading = false;
    },
    async getBinaryCaps(binary) {
      return await vertebrClient.call('caps:get', { binary });
    },
    async grant(binary, capabilities) {
      return await vertebrClient.call('caps:grant', { binary, capabilities });
    },
    async revoke(binary) {
      return await vertebrClient.call('caps:revoke', { binary });
    },
  },
});
