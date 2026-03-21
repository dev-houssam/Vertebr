<template>
  <div class="dashboard">
    <div class="dash-header">
      <div>
        <h1 class="section-title">Bonjour 👋</h1>
        <p class="section-subtitle">Vue d'ensemble de votre système</p>
      </div>
      <div class="text-sm text-muted">{{ currentDate }}</div>
    </div>

    <!-- Quick status grid -->
    <div class="status-grid">
      <!-- Wi-Fi -->
      <router-link to="/wifi" class="status-card glass card-interactive">
        <div class="status-icon" style="background:rgba(77,163,255,0.12)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2">
            <path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/>
            <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1" fill="var(--accent)"/>
          </svg>
        </div>
        <div class="status-info">
          <div class="status-name">Wi-Fi</div>
          <div class="status-value" :class="wifiStore.isConnected ? 'text-success' : 'text-muted'">
            {{ wifiStore.isConnected ? wifiStore.status.connected_to : 'Non connecté' }}
          </div>
        </div>
        <svg class="chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="9 18 15 12 9 6"/>
        </svg>
      </router-link>

      <!-- Bluetooth -->
      <router-link to="/bluetooth" class="status-card glass card-interactive">
        <div class="status-icon" style="background:rgba(127,92,255,0.12)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#7f5cff" stroke-width="2">
            <polyline points="6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5"/>
          </svg>
        </div>
        <div class="status-info">
          <div class="status-name">Bluetooth</div>
          <div class="status-value" :class="btStore.status.enabled ? 'text-success' : 'text-muted'">
            {{ btStore.status.enabled ? `${btStore.connectedDevices.length} connecté${btStore.connectedDevices.length > 1 ? 's' : ''}` : 'Désactivé' }}
          </div>
        </div>
        <svg class="chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="9 18 15 12 9 6"/>
        </svg>
      </router-link>

      <!-- Battery -->
      <router-link to="/power" class="status-card glass card-interactive" v-if="powerStore.status.has_battery">
        <div class="status-icon" :style="batteryIconStyle">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="batteryColor" stroke-width="2">
            <rect x="1" y="6" width="18" height="12" rx="2"/><line x1="23" y1="11" x2="23" y2="13"/>
          </svg>
        </div>
        <div class="status-info">
          <div class="status-name">Batterie</div>
          <div class="status-value" :style="{color: batteryColor}">
            {{ powerStore.status.battery_percent }}% · {{ powerStore.status.battery_state }}
          </div>
        </div>
        <svg class="chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="9 18 15 12 9 6"/>
        </svg>
      </router-link>

      <!-- Theme -->
      <router-link to="/theme" class="status-card glass card-interactive">
        <div class="status-icon" style="background:var(--accent-dim)">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2">
            <circle cx="13.5" cy="6.5" r=".5" fill="currentColor"/><circle cx="17.5" cy="10.5" r=".5" fill="currentColor"/>
            <circle cx="8.5" cy="7.5" r=".5" fill="currentColor"/><circle cx="6.5" cy="12.5" r=".5" fill="currentColor"/>
            <path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/>
          </svg>
        </div>
        <div class="status-info">
          <div class="status-name">Apparence</div>
          <div class="status-value text-muted">{{ themeStore.isDark ? 'Mode sombre' : 'Mode clair' }} · {{ themeStore.gtkTheme }}</div>
        </div>
        <svg class="chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="9 18 15 12 9 6"/>
        </svg>
      </router-link>
    </div>

    <!-- Quick actions -->
    <h2 class="text-lg font-semi mt-28 mb-12">Actions rapides</h2>
    <div class="quick-actions">
      <button class="quick-action glass card-interactive" @click="wifiStore.setAirplaneMode(!wifiStore.status.airplane_mode)">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" :stroke="wifiStore.status.airplane_mode ? 'var(--warning)' : 'var(--text-secondary)'" stroke-width="2">
          <path d="M17.67 3.34A10 10 0 1 1 6.33 20.66"/><path d="M17.67 3.34 12 12 17.67 3.34z" fill="currentColor" stroke="none"/>
        </svg>
        <span class="text-sm">Mode avion</span>
        <span class="badge" :class="wifiStore.status.airplane_mode ? 'badge-warning' : 'badge-muted'">
          {{ wifiStore.status.airplane_mode ? 'ON' : 'OFF' }}
        </span>
      </button>

      <button class="quick-action glass card-interactive" @click="powerStore.suspend()">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" stroke-width="2">
          <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>
        </svg>
        <span class="text-sm">Veille</span>
      </button>

      <button class="quick-action glass card-interactive" @click="themeStore.setMode(themeStore.isDark ? 'light' : 'dark')">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" stroke-width="2">
          <circle cx="12" cy="12" r="5"/>
          <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/>
        </svg>
        <span class="text-sm">{{ themeStore.isDark ? 'Mode clair' : 'Mode sombre' }}</span>
      </button>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue';
import { useWifiStore }      from '@/stores/wifi.store.js';
import { useBluetoothStore } from '@/stores/bluetooth.store.js';
import { usePowerStore }     from '@/stores/power.store.js';
import { useThemeStore }     from '@/stores/theme.store.js';

const wifiStore  = useWifiStore();
const btStore    = useBluetoothStore();
const powerStore = usePowerStore();
const themeStore = useThemeStore();

onMounted(() => {
  wifiStore.load();
  btStore.load();
  powerStore.load();
});

const currentDate = computed(() => new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' }));

const batteryColor = computed(() => {
  const p = powerStore.status.battery_percent;
  if (p <= 15) return 'var(--danger)';
  if (p <= 35) return 'var(--warning)';
  return 'var(--success)';
});

const batteryIconStyle = computed(() => {
  const p = powerStore.status.battery_percent;
  if (p <= 15) return 'background:rgba(255,92,92,0.12)';
  if (p <= 35) return 'background:rgba(245,166,35,0.12)';
  return 'background:rgba(61,214,140,0.12)';
});
</script>
<style scoped>
.dashboard { max-width: 720px; }
.dash-header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 24px; }
.status-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }
.status-card { display: flex; align-items: center; gap: 14px; padding: 16px 18px; text-decoration: none; color: inherit; }
.status-icon { width: 44px; height: 44px; border-radius: var(--radius-md); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.status-info { flex: 1; min-width: 0; }
.status-name  { font-size: 13px; color: var(--text-secondary); margin-bottom: 2px; }
.status-value { font-size: 14px; font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.chevron      { color: var(--text-tertiary); flex-shrink: 0; }
.quick-actions { display: flex; gap: 10px; }
.quick-action  { flex: 1; display: flex; align-items: center; gap: 10px; padding: 14px 16px; cursor: pointer; border: none; color: var(--text-primary); }
</style>
