<template>
  <div class="bt-view">
    <div class="section-header">
      <div>
        <h1 class="section-title">Bluetooth</h1>
        <p class="section-subtitle">Gérer les périphériques sans fil</p>
      </div>
      <button class="btn btn-ghost btn-sm" @click="load">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/>
        </svg>
        Actualiser
      </button>
    </div>

    <!-- Toggle -->
    <div class="glass control-card">
      <div class="control-row">
        <div class="flex gap-12" style="align-items:center">
          <div class="icon-box" style="background:rgba(127,92,255,0.12)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#7f5cff" stroke-width="2">
              <polyline points="6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5"/>
            </svg>
          </div>
          <div>
            <div class="font-medium">Bluetooth</div>
            <div class="text-sm text-muted">{{ btStore.status.enabled ? `Activé — ${btStore.status.adapter}` : 'Désactivé' }}</div>
          </div>
        </div>
        <label class="toggle">
          <input type="checkbox" :checked="btStore.status.enabled" @change="e => btStore.setPower(e.target.checked)" />
          <div class="toggle-track"></div>
          <div class="toggle-thumb"></div>
        </label>
      </div>
    </div>

    <!-- Devices -->
    <div class="mt-24" v-if="btStore.status.enabled">
      <div class="section-header">
        <h2 class="text-lg font-semi">Périphériques couplés</h2>
        <span class="text-sm text-muted">{{ btStore.pairedDevices.length }} périphérique{{ btStore.pairedDevices.length > 1 ? 's' : '' }}</span>
      </div>

      <div v-if="btStore.loading" class="flex-center" style="padding:40px">
        <div class="spinner"></div>
      </div>

      <div v-else-if="btStore.pairedDevices.length" class="devices-list glass">
        <div
          v-for="(dev, i) in btStore.pairedDevices"
          :key="dev.address"
          class="device-item"
          :class="{ 'border-bottom': i < btStore.pairedDevices.length - 1 }"
        >
          <div class="device-icon-wrap" :style="deviceIconStyle(dev.device_type)">
            <span v-html="deviceIconSvg(dev.device_type)"></span>
          </div>
          <div class="device-info flex-col gap-4">
            <div class="flex gap-8" style="align-items:center">
              <span class="font-medium">{{ dev.name }}</span>
              <span v-if="dev.connected" class="badge badge-success">Connecté</span>
            </div>
            <span class="text-sm text-muted">{{ dev.address }}</span>
          </div>
          <div class="device-actions flex gap-6">
            <button v-if="!dev.connected" class="btn btn-ghost btn-sm" @click="connect(dev.address)">Connecter</button>
            <button v-else class="btn btn-ghost btn-sm" @click="disconnect(dev.address)">Déconnecter</button>
            <button class="btn btn-icon btn-ghost btn-sm" @click="remove(dev.address)" title="Supprimer">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/>
              </svg>
            </button>
          </div>
        </div>
      </div>

      <div v-else class="glass flex-center flex-col" style="padding:40px;gap:12px">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--text-tertiary)" stroke-width="1.5">
          <polyline points="6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5"/>
        </svg>
        <p class="text-muted">Aucun périphérique couplé</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue';
import { useBluetoothStore } from '@/stores/bluetooth.store.js';

const btStore = useBluetoothStore();

onMounted(() => btStore.load());

async function load()           { await btStore.load(); }
async function connect(addr)    { await btStore.connect(addr);    await btStore.load(); }
async function disconnect(addr) { await btStore.disconnect(addr); await btStore.load(); }
async function remove(addr)     { await btStore.remove(addr); }

function deviceIconStyle(type) {
  const colors = { headphones: '#4da3ff', keyboard: '#3dd68c', mouse: '#f5a623', phone: '#7f5cff', speaker: '#ff5c5c', device: '#8a8fa8' };
  const c = colors[type] || colors.device;
  return { background: c + '20', color: c };
}

function deviceIconSvg(type) {
  const icons = {
    headphones: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 18v-6a9 9 0 0 1 18 0v6"/><path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/></svg>`,
    keyboard:   `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="6" width="20" height="12" rx="2"/><path d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M8 14h8"/></svg>`,
    mouse:      `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="7"/><path d="M12 2v6M5 10h14"/></svg>`,
    phone:      `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="2"/><circle cx="12" cy="18" r="1" fill="currentColor"/></svg>`,
    speaker:    `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2"/><circle cx="12" cy="14" r="4"/><circle cx="12" cy="14" r="1" fill="currentColor"/><line x1="12" y1="6" x2="12" y2="6"/></svg>`,
    device:     `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5"/></svg>`,
  };
  return icons[type] || icons.device;
}
</script>

<style scoped>
.bt-view { max-width: 680px; }
.control-card { padding: 4px 0; }
.control-row  { display: flex; align-items: center; justify-content: space-between; padding: 14px 20px; }
.devices-list { padding: 4px; }
.device-item  { display: flex; align-items: center; gap: 14px; padding: 14px 16px; border-radius: var(--radius-md); transition: var(--transition); }
.device-item:hover { background: var(--card-bg-hover); }
.border-bottom { border-bottom: 1px solid var(--card-border); border-radius: 0; }
.device-icon-wrap { width: 40px; height: 40px; border-radius: var(--radius-sm); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.device-info { flex: 1; }
.device-actions { opacity: 0; transition: var(--transition); }
.device-item:hover .device-actions { opacity: 1; }
</style>
