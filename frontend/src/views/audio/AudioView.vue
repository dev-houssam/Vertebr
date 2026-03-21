<template>
  <div class="audio-view">
    <div class="section-header">
      <div><h1 class="section-title">Son</h1><p class="section-subtitle">Entrées, sorties et niveaux audio</p></div>
    </div>

    <!-- Output -->
    <h2 class="text-lg font-semi mb-12">Sorties audio</h2>
    <div class="glass audio-list">
      <div v-for="(sink, i) in audioStore.sinks" :key="sink.name"
        class="audio-item" :class="{'border-bottom': i < audioStore.sinks.length - 1, 'active': sink.is_default}">
        <div class="audio-left">
          <div class="icon-box" :style="sink.is_default ? 'background:var(--accent-dim)' : 'background:var(--card-bg)'">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" :stroke="sink.is_default ? 'var(--accent)' : 'var(--text-secondary)'" stroke-width="2">
              <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
              <path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/>
            </svg>
          </div>
          <div class="flex-col gap-4">
            <span class="font-medium">{{ sink.description }}</span>
            <span class="text-sm text-muted">{{ sink.name }}</span>
          </div>
        </div>
        <div class="audio-controls">
          <button class="mute-btn" :class="{muted: sink.muted}" @click="audioStore.setMute(sink.name, !sink.muted)">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polygon v-if="!sink.muted" points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
              <line v-else x1="1" y1="1" x2="23" y2="23"/>
            </svg>
          </button>
          <div class="volume-wrap">
            <input type="range" min="0" max="100" :value="sink.volume" class="range"
              @input="e => audioStore.setVolume(sink.name, Number(e.target.value))" />
            <span class="vol-label">{{ sink.volume }}%</span>
          </div>
          <button v-if="!sink.is_default" class="btn btn-ghost btn-sm" @click="audioStore.setDefault(sink.name)">Défaut</button>
          <span v-else class="badge badge-accent" style="font-size:10px">Défaut</span>
        </div>
      </div>
    </div>

    <!-- Input -->
    <h2 class="text-lg font-semi mt-24 mb-12">Entrées audio (microphones)</h2>
    <div class="glass audio-list">
      <div v-for="(src, i) in audioStore.sources" :key="src.name"
        class="audio-item" :class="{'border-bottom': i < audioStore.sources.length - 1, 'active': src.is_default}">
        <div class="audio-left">
          <div class="icon-box" :style="src.is_default ? 'background:var(--accent-dim)' : 'background:var(--card-bg)'">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" :stroke="src.is_default ? 'var(--accent)' : 'var(--text-secondary)'" stroke-width="2">
              <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/>
              <path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/>
            </svg>
          </div>
          <div class="flex-col gap-4">
            <span class="font-medium">{{ src.description }}</span>
            <span class="text-sm text-muted">{{ src.name }}</span>
          </div>
        </div>
        <div class="audio-controls">
          <button class="mute-btn" :class="{muted: src.muted}" @click="audioStore.setMute(src.name, !src.muted, false)">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path v-if="!src.muted" d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/>
              <line v-else x1="1" y1="1" x2="23" y2="23"/>
            </svg>
          </button>
          <div class="volume-wrap">
            <input type="range" min="0" max="100" :value="src.volume" class="range"
              @input="e => audioStore.setVolume(src.name, Number(e.target.value), false)" />
            <span class="vol-label">{{ src.volume }}%</span>
          </div>
          <span v-if="src.is_default" class="badge badge-accent" style="font-size:10px">Défaut</span>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { onMounted } from 'vue';
import { useAudioStore } from '@/stores/audio.store.js';
const audioStore = useAudioStore();
onMounted(() => audioStore.load());
</script>
<style scoped>
.audio-view { max-width: 680px; }
.audio-list  { padding: 4px; }
.audio-item  { display: flex; align-items: center; justify-content: space-between; gap: 14px; padding: 14px 16px; border-radius: var(--radius-md); transition: var(--transition); }
.audio-item:hover { background: var(--card-bg-hover); }
.audio-item.active { background: var(--accent-dim); }
.border-bottom { border-bottom: 1px solid var(--card-border); border-radius: 0; }
.audio-left  { display: flex; align-items: center; gap: 12px; flex: 1; min-width: 0; }
.audio-controls { display: flex; align-items: center; gap: 10px; }
.volume-wrap { display: flex; align-items: center; gap: 8px; }
.vol-label   { font-size: 12px; color: var(--text-muted); width: 36px; text-align: right; }
.mute-btn    { width: 32px; height: 32px; border: none; border-radius: 50%; background: var(--card-bg); color: var(--text-secondary); cursor: pointer; display: flex; align-items: center; justify-content: center; transition: var(--transition); }
.mute-btn:hover { background: var(--card-bg-hover); }
.mute-btn.muted { background: rgba(255,92,92,0.15); color: var(--danger); }
</style>
