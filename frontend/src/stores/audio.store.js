// VERTEBR — stores/audio.store.js
// Auteur : Houssam | Licence : MIT
import { defineStore } from 'pinia';
import { vertebrClient } from '@/services/api/vertebr-client';

export const useAudioStore = defineStore('audio', {
  state: () => ({
    sinks:   [],
    sources: [],
    loading: false,
  }),
  getters: {
    defaultSink:   (s) => s.sinks.find(k => k.is_default),
    defaultSource: (s) => s.sources.find(k => k.is_default),
  },
  actions: {
    async load() {
      this.loading = true;
      const [sinksRes, sourcesRes] = await Promise.all([
        vertebrClient.call('audio:sinks'),
        vertebrClient.call('audio:sources'),
      ]);
      if (sinksRes.status   === 'success') this.sinks   = sinksRes.data;
      if (sourcesRes.status === 'success') this.sources = sourcesRes.data;
      this.loading = false;
    },
    async setVolume(name, volume, isSink = true) {
      const key  = isSink ? 'sink' : 'source';
      await vertebrClient.call('audio:volume', { [key]: name, volume });
      const item = (isSink ? this.sinks : this.sources).find(s => s.name === name);
      if (item) item.volume = volume;
    },
    async setMute(name, muted, isSink = true) {
      const key  = isSink ? 'sink' : 'source';
      await vertebrClient.call('audio:mute', { [key]: name, muted });
      const item = (isSink ? this.sinks : this.sources).find(s => s.name === name);
      if (item) item.muted = muted;
    },
    async setDefault(name) {
      await vertebrClient.call('audio:default', { name });
      this.sinks.forEach(s => { s.is_default = s.name === name; });
    },
  },
});
