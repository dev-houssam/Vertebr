<template>
  <div class="app-shell" :class="themeStore.mode">
    <!-- Titlebar custom (frameless window) -->
    <div class="titlebar">
      <div class="titlebar-drag">
        <span class="app-logo">🦴</span>
        <span class="app-name">Vertebr</span>
      </div>
      <div class="titlebar-controls">
        <button class="win-btn minimize" @click="windowControls?.minimize()">
          <svg width="10" height="2" viewBox="0 0 10 2"><rect width="10" height="2" rx="1" fill="currentColor"/></svg>
        </button>
        <button class="win-btn maximize" @click="windowControls?.maximize()">
          <svg width="10" height="10" viewBox="0 0 10 10"><rect x="1" y="1" width="8" height="8" rx="2" stroke="currentColor" stroke-width="1.5" fill="none"/></svg>
        </button>
        <button class="win-btn close" @click="windowControls?.close()">
          <svg width="10" height="10" viewBox="0 0 10 10">
            <line x1="1" y1="1" x2="9" y2="9" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
            <line x1="9" y1="1" x2="1" y2="9" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
        </button>
      </div>
    </div>

    <!-- Main layout -->
    <div class="app-body">
      <SideMenu />
      <main class="main-content">
        <router-view v-slot="{ Component }">
          <transition name="page" mode="out-in">
            <component :is="Component" :key="$route.path" />
          </transition>
        </router-view>
      </main>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue';
import { useThemeStore } from '@/stores/theme.store.js';
import SideMenu from '@/components/layout/SideMenu.vue';

const themeStore = useThemeStore();

onMounted(() => {
  themeStore.init();
});
</script>

<style scoped>
.app-shell {
  display:        flex;
  flex-direction: column;
  height:         100vh;
  overflow:       hidden;
  background:     var(--bg);
}

/* ── Titlebar ── */
.titlebar {
  display:         flex;
  align-items:     center;
  justify-content: space-between;
  padding:         0 16px;
  height:          38px;
  flex-shrink:     0;
  background:      rgba(0,0,0,0.2);
  border-bottom:   1px solid var(--card-border);
  -webkit-app-region: drag;
  user-select:     none;
}

.titlebar-drag {
  display:     flex;
  align-items: center;
  gap:         8px;
}

.app-logo { font-size: 14px; }
.app-name {
  font-size:   13px;
  font-weight: 600;
  color:       var(--text-secondary);
  letter-spacing: 0.5px;
}

.titlebar-controls {
  display:             flex;
  gap:                 6px;
  -webkit-app-region:  no-drag;
}

.win-btn {
  display:         flex;
  align-items:     center;
  justify-content: center;
  width:           24px;
  height:          24px;
  border:          none;
  border-radius:   50%;
  background:      var(--card-bg);
  color:           var(--text-tertiary);
  cursor:          pointer;
  transition:      all 0.15s ease;
}
.win-btn:hover         { background: var(--card-bg-hover); color: var(--text-primary); }
.win-btn.close:hover   { background: rgba(255,92,92,0.2);  color: var(--danger); }
.win-btn.minimize:hover{ background: rgba(245,166,35,0.2); color: var(--warning); }
.win-btn.maximize:hover{ background: rgba(77,163,255,0.2); color: var(--accent); }

/* ── Body ── */
.app-body {
  display:   flex;
  flex:      1;
  overflow:  hidden;
}

.main-content {
  flex:       1;
  overflow-y: auto;
  padding:    28px 32px;
  background: radial-gradient(ellipse 80% 50% at 50% -10%, rgba(77,163,255,0.04) 0%, transparent 70%);
}
</style>
