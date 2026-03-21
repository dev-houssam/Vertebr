<template>
  <div class="theme-view">
    <div class="section-header">
      <div><h1 class="section-title">Apparence</h1><p class="section-subtitle">Thème, couleurs et personnalisation visuelle</p></div>
    </div>

    <!-- Light / Dark -->
    <div class="glass section-card">
      <h3 class="card-title">Mode d'affichage</h3>
      <div class="mode-row">
        <div class="mode-option" :class="{selected: !themeStore.isDark}" @click="themeStore.setMode('light')">
          <div class="mode-preview light-preview">
            <div class="preview-sidebar"></div><div class="preview-content"><div class="preview-card"></div></div>
          </div>
          <span class="mode-label">Clair</span>
          <div v-if="!themeStore.isDark" class="mode-check">✓</div>
        </div>
        <div class="mode-option" :class="{selected: themeStore.isDark}" @click="themeStore.setMode('dark')">
          <div class="mode-preview dark-preview">
            <div class="preview-sidebar"></div><div class="preview-content"><div class="preview-card"></div></div>
          </div>
          <span class="mode-label">Sombre</span>
          <div v-if="themeStore.isDark" class="mode-check">✓</div>
        </div>
      </div>
      <div class="control-row mt-16">
        <div>
          <div class="font-medium">Suivre le thème système</div>
          <div class="text-sm text-muted">S'adapte automatiquement au thème GNOME</div>
        </div>
        <label class="toggle">
          <input type="checkbox" :checked="themeStore.followSystem" @change="e => { if (e.target.checked) themeStore.enableFollowSystem(); else themeStore.followSystem = false; }" />
          <div class="toggle-track"></div><div class="toggle-thumb"></div>
        </label>
      </div>
    </div>

    <!-- Accent colors -->
    <div class="glass section-card mt-16">
      <h3 class="card-title">Couleur d'accent</h3>
      <div class="accent-palette">
        <div v-for="color in accentColors" :key="color.hex"
          class="accent-swatch" :style="{background: color.gradient}"
          :class="{selected: themeStore.accentColor === color.hex}"
          @click="themeStore.setAccent(color.hex)" :title="color.name">
          <svg v-if="themeStore.accentColor === color.hex" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
        </div>
      </div>
    </div>

    <!-- GTK Theme -->
    <div class="glass section-card mt-16">
      <h3 class="card-title">Thème GTK</h3>
      <div class="gtk-grid">
        <div v-for="theme in themeStore.availableThemes" :key="theme"
          class="gtk-chip" :class="{selected: themeStore.gtkTheme === theme}"
          @click="themeStore.setGtkTheme(theme)">
          {{ theme }}
        </div>
      </div>
    </div>

    <!-- Font & info -->
    <div class="glass section-card mt-16">
      <h3 class="card-title">Police système</h3>
      <div class="font-display">
        <span class="font-sample">{{ themeStore.fontName }}</span>
        <span class="text-sm text-muted">Modifier via GNOME Tweaks</span>
      </div>
    </div>
  </div>
</template>
<script setup>
import { useThemeStore } from '@/stores/theme.store.js';
const themeStore = useThemeStore();

const accentColors = [
  { hex: '#4da3ff', gradient: 'linear-gradient(135deg,#4da3ff,#7f5cff)', name: 'Bleu (défaut)' },
  { hex: '#7f5cff', gradient: 'linear-gradient(135deg,#7f5cff,#c084fc)', name: 'Violet' },
  { hex: '#3dd68c', gradient: 'linear-gradient(135deg,#3dd68c,#06b6d4)', name: 'Vert' },
  { hex: '#f5a623', gradient: 'linear-gradient(135deg,#f5a623,#ef4444)', name: 'Orange' },
  { hex: '#ff5c5c', gradient: 'linear-gradient(135deg,#ff5c5c,#f97316)', name: 'Rouge' },
  { hex: '#ec4899', gradient: 'linear-gradient(135deg,#ec4899,#7f5cff)', name: 'Rose' },
  { hex: '#06b6d4', gradient: 'linear-gradient(135deg,#06b6d4,#3dd68c)', name: 'Cyan' },
  { hex: '#f0f1f5', gradient: 'linear-gradient(135deg,#f0f1f5,#c0c4d4)', name: 'Blanc' },
];
</script>
<style scoped>
.theme-view { max-width: 680px; }
.section-card { padding: 20px; }
.card-title   { font-size: 13px; font-weight: 600; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.6px; margin-bottom: 16px; }
.control-row  { display: flex; align-items: center; justify-content: space-between; }
.mode-row     { display: flex; gap: 16px; }
.mode-option  { flex: 1; cursor: pointer; border-radius: var(--radius-md); overflow: hidden; border: 2px solid var(--card-border); transition: var(--transition); position: relative; }
.mode-option:hover  { border-color: var(--text-secondary); }
.mode-option.selected { border-color: var(--accent); }
.mode-preview { height: 72px; display: flex; }
.light-preview { background: #e8eaf0; }
.dark-preview  { background: #0f1115; }
.light-preview .preview-sidebar { width: 30%; background: rgba(0,0,0,0.06); }
.dark-preview  .preview-sidebar { width: 30%; background: rgba(255,255,255,0.04); }
.preview-content { flex: 1; padding: 8px; }
.light-preview .preview-card { height: 30px; background: rgba(255,255,255,0.8); border-radius: 6px; }
.dark-preview  .preview-card { height: 30px; background: rgba(255,255,255,0.06); border-radius: 6px; }
.mode-label  { display: block; padding: 8px 12px; font-size: 13px; font-weight: 500; }
.mode-check  { position: absolute; top: 8px; right: 8px; width: 18px; height: 18px; background: var(--accent); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 10px; color: #fff; }
.accent-palette { display: flex; gap: 10px; flex-wrap: wrap; }
.accent-swatch  { width: 36px; height: 36px; border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center; border: 2px solid transparent; transition: var(--transition); }
.accent-swatch:hover  { transform: scale(1.15); }
.accent-swatch.selected { border-color: var(--text-primary); transform: scale(1.15); }
.gtk-grid  { display: flex; flex-wrap: wrap; gap: 8px; }
.gtk-chip  { padding: 6px 14px; border-radius: var(--radius-xl); background: var(--card-bg); border: 1px solid var(--card-border); font-size: 12px; cursor: pointer; transition: var(--transition); }
.gtk-chip:hover   { background: var(--card-bg-hover); border-color: var(--text-tertiary); }
.gtk-chip.selected { background: var(--accent-dim); border-color: var(--accent); color: var(--accent); }
.font-display { display: flex; align-items: center; justify-content: space-between; }
.font-sample  { font-size: 16px; font-weight: 400; }
</style>
