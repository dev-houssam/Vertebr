<template>
  <div class="wifi-view">
    <!-- Header -->
    <div class="section-header">
      <div>
        <h1 class="section-title">Wi-Fi</h1>
        <p class="section-subtitle">Gérer les connexions réseau sans fil</p>
      </div>
      <div class="flex gap-8">
        <button class="btn btn-ghost btn-sm" @click="load" :disabled="loading">
          <span v-if="loading" class="spinner" style="width:12px;height:12px;border-width:1.5px"></span>
          <svg v-else width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/>
          </svg>
          Actualiser
        </button>
      </div>
    </div>

    <!-- Controls card -->
    <div class="glass control-card">
      <div class="control-row">
        <div class="flex gap-12 align-center">
          <div class="icon-box" style="background:rgba(77,163,255,0.12)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2">
              <path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/>
              <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1" fill="var(--accent)"/>
            </svg>
          </div>
          <div>
            <div class="font-medium">Wi-Fi</div>
            <div class="text-sm text-muted">
              {{ wifiStore.status.enabled ? (wifiStore.status.connected_to ? `Connecté à ${wifiStore.status.connected_to}` : 'Activé, non connecté') : 'Désactivé' }}
            </div>
          </div>
        </div>
        <label class="toggle">
          <input type="checkbox" :checked="wifiStore.status.enabled" @change="toggleWifi" />
          <div class="toggle-track"></div>
          <div class="toggle-thumb"></div>
        </label>
      </div>

      <div class="divider"></div>

      <div class="control-row">
        <div class="flex gap-12 align-center">
          <div class="icon-box" style="background:rgba(245,166,35,0.12)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--warning)" stroke-width="2">
              <path d="M17.67 3.34A10 10 0 1 1 6.33 20.66"/><path d="M17.67 3.34L12 12l5.67-8.66z" fill="var(--warning)" stroke="none"/>
            </svg>
          </div>
          <div>
            <div class="font-medium">Mode avion</div>
            <div class="text-sm text-muted">Désactive toutes les connexions sans fil</div>
          </div>
        </div>
        <label class="toggle">
          <input type="checkbox" :checked="wifiStore.status.airplane_mode" @change="toggleAirplane" />
          <div class="toggle-track"></div>
          <div class="toggle-thumb"></div>
        </label>
      </div>
    </div>

    <!-- Connected network -->
    <transition name="slide-up">
      <div v-if="wifiStore.connectedNetwork" class="glass connected-card mt-16">
        <div class="connected-header">
          <div class="flex gap-8 align-center">
            <div class="dot-connected"></div>
            <span class="text-sm text-muted">Connecté</span>
          </div>
          <button class="btn btn-ghost btn-sm" @click="disconnect">Se déconnecter</button>
        </div>
        <div class="connected-info">
          <div class="connected-name">{{ wifiStore.connectedNetwork.name }}</div>
          <div class="flex gap-12 mt-4">
            <span class="badge badge-success">{{ wifiStore.connectedNetwork.security }}</span>
            <span class="text-sm text-muted">{{ wifiStore.connectedNetwork.frequency }}</span>
            <span class="text-sm text-muted">Signal: {{ wifiStore.connectedNetwork.signal }}%</span>
          </div>
        </div>
      </div>
    </transition>

    <!-- Networks list -->
    <div class="mt-24">
      <div class="section-header">
        <h2 class="text-lg font-semi">Réseaux disponibles</h2>
        <span class="text-sm text-muted">{{ filteredNetworks.length }} réseau{{ filteredNetworks.length > 1 ? 'x' : '' }}</span>
      </div>

      <!-- Loading state -->
      <div v-if="loading && !wifiStore.networks.length" class="networks-skeleton">
        <div v-for="i in 4" :key="i" class="skeleton-item skeleton"></div>
      </div>

      <!-- Networks -->
      <div v-else class="networks-list glass">
        <div
          v-for="(network, i) in filteredNetworks"
          :key="network.bssid || network.name"
          class="network-item"
          :class="{ 'border-bottom': i < filteredNetworks.length - 1 }"
          @click="openConnect(network)"
        >
          <!-- Signal bars -->
          <div class="signal-bars" :class="signalClass(network.signal)">
            <span></span><span></span><span></span><span></span>
          </div>

          <!-- Info -->
          <div class="network-info">
            <div class="flex gap-8 align-center">
              <span class="network-name">{{ network.name }}</span>
              <span v-if="network.in_use" class="badge badge-success" style="font-size:10px">Connecté</span>
            </div>
            <div class="flex gap-8 mt-4">
              <span class="text-sm text-muted">{{ network.frequency }}</span>
              <span v-if="network.secured" class="text-sm text-muted flex gap-4 align-center">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
                </svg>
                {{ network.security }}
              </span>
            </div>
          </div>

          <!-- Actions -->
          <div class="network-actions" @click.stop>
            <button class="btn btn-ghost btn-sm" @click="openConnect(network)">
              {{ network.in_use ? 'Connecté' : 'Connecter' }}
            </button>
            <button v-if="network.in_use" class="btn btn-icon btn-ghost" title="Oublier" @click.stop="forgetNetwork(network.name)">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/>
                <path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
              </svg>
            </button>
          </div>
        </div>

        <!-- Empty state -->
        <div v-if="!loading && !filteredNetworks.length" class="empty-state">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--text-tertiary)" stroke-width="1.5">
            <line x1="1" y1="1" x2="23" y2="23"/>
            <path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/>
            <path d="M10.71 5.05A16 16 0 0 1 22.56 9"/><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/>
            <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><line x1="12" y1="20" x2="12.01" y2="20"/>
          </svg>
          <p class="text-muted mt-12">Aucun réseau détecté</p>
          <button class="btn btn-ghost btn-sm mt-8" @click="load">Scanner à nouveau</button>
        </div>
      </div>
    </div>

    <!-- Connect Modal -->
    <transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal-content glass">
          <div class="modal-header">
            <div>
              <h3 class="font-semi">Connexion à {{ selectedNetwork?.name }}</h3>
              <p class="text-sm text-muted mt-4">{{ selectedNetwork?.frequency }} · {{ selectedNetwork?.security }}</p>
            </div>
            <button class="btn btn-icon btn-ghost" @click="closeModal">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
              </svg>
            </button>
          </div>
          <div class="modal-body">
            <div v-if="selectedNetwork?.secured">
              <label class="text-sm text-muted" style="display:block;margin-bottom:8px">Mot de passe</label>
              <div class="password-wrap">
                <input
                  v-model="password"
                  :type="showPwd ? 'text' : 'password'"
                  class="input"
                  placeholder="Entrez le mot de passe Wi-Fi"
                  @keyup.enter="doConnect"
                  autofocus
                />
                <button class="eye-btn" @click="showPwd = !showPwd">
                  <svg v-if="!showPwd" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                  </svg>
                  <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                </button>
              </div>
            </div>
            <p v-else class="text-sm text-muted">Réseau ouvert — aucun mot de passe requis.</p>
            <p v-if="connectError" class="text-sm text-danger mt-8">{{ connectError }}</p>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" @click="closeModal">Annuler</button>
            <button class="btn btn-primary" @click="doConnect" :disabled="connecting">
              <span v-if="connecting" class="spinner" style="width:12px;height:12px;border-width:1.5px;border-color:rgba(255,255,255,0.3);border-top-color:#fff"></span>
              {{ connecting ? 'Connexion…' : 'Se connecter' }}
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useWifiStore } from '@/stores/wifi.store.js';

const wifiStore = useWifiStore();
const loading   = ref(false);

// Modal state
const showModal       = ref(false);
const selectedNetwork = ref(null);
const password        = ref('');
const showPwd         = ref(false);
const connecting      = ref(false);
const connectError    = ref('');

const filteredNetworks = computed(() =>
  wifiStore.networks.filter(n => !n.in_use)
);

function signalClass(signal) {
  if (signal >= 75) return 's4';
  if (signal >= 50) return 's3';
  if (signal >= 25) return 's2';
  return 's1';
}

async function load() {
  loading.value = true;
  await wifiStore.load();
  loading.value = false;
}

function openConnect(network) {
  if (network.in_use) return;
  selectedNetwork.value = network;
  password.value   = '';
  connectError.value = '';
  showModal.value  = true;
}

function closeModal() {
  showModal.value = false;
  connecting.value = false;
  connectError.value = '';
}

async function doConnect() {
  connecting.value = true;
  connectError.value = '';
  const res = await wifiStore.connect(
    selectedNetwork.value.name,
    selectedNetwork.value.secured ? password.value : null
  );
  if (res.status === 'success') {
    closeModal();
  } else {
    connectError.value = res.error || 'Connexion échouée';
    connecting.value = false;
  }
}

async function disconnect() {
  await wifiStore.disconnect();
}

async function forgetNetwork(ssid) {
  await wifiStore.forget(ssid);
}

async function toggleWifi(e) {
  await wifiStore.setEnabled(e.target.checked);
}

async function toggleAirplane(e) {
  await wifiStore.setAirplaneMode(e.target.checked);
}

onMounted(load);
</script>

<style scoped>
.wifi-view { max-width: 680px; }

/* Control card */
.control-card { padding: 4px 0; }
.control-row {
  display:         flex;
  align-items:     center;
  justify-content: space-between;
  padding:         14px 20px;
}
.align-center { align-items: center; }

/* Connected card */
.connected-card { padding: 16px 20px; }
.connected-header {
  display:         flex;
  align-items:     center;
  justify-content: space-between;
  margin-bottom:   12px;
}
.connected-name {
  font-size:   20px;
  font-weight: 600;
  color:       var(--text-primary);
}
.dot-connected {
  width:         8px;
  height:        8px;
  border-radius: 50%;
  background:    var(--success);
  box-shadow:    0 0 6px var(--success);
  animation:     pulse-dot 2s infinite;
}
@keyframes pulse-dot {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.5; }
}

/* Networks list */
.networks-list { padding: 4px; overflow: hidden; }
.network-item {
  display:       flex;
  align-items:   center;
  gap:           14px;
  padding:       12px 16px;
  border-radius: var(--radius-md);
  cursor:        pointer;
  transition:    var(--transition);
}
.network-item:hover { background: var(--card-bg-hover); }
.border-bottom { border-bottom: 1px solid var(--card-border); border-radius: 0; }
.border-bottom:last-child { border-bottom: none; }

.network-info { flex: 1; min-width: 0; }
.network-name {
  font-size:   14px;
  font-weight: 500;
  color:       var(--text-primary);
  overflow:    hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.network-actions {
  display: flex;
  gap:     6px;
  opacity: 0;
  transition: var(--transition);
}
.network-item:hover .network-actions { opacity: 1; }

/* Skeleton */
.networks-skeleton { display: flex; flex-direction: column; gap: 4px; }
.skeleton-item { height: 62px; border-radius: var(--radius-md); }

/* Empty state */
.empty-state {
  display:         flex;
  flex-direction:  column;
  align-items:     center;
  padding:         40px 20px;
  color:           var(--text-tertiary);
}

/* Modal */
.modal-header {
  display:         flex;
  align-items:     flex-start;
  justify-content: space-between;
  padding:         20px 20px 0;
}
.modal-body    { padding: 16px 20px; }
.modal-footer  { padding: 12px 20px 20px; display: flex; justify-content: flex-end; gap: 8px; }

.password-wrap { position: relative; }
.eye-btn {
  position:    absolute;
  right:       12px;
  top:         50%;
  transform:   translateY(-50%);
  background:  none;
  border:      none;
  color:       var(--text-tertiary);
  cursor:      pointer;
  padding:     4px;
  transition:  var(--transition);
}
.eye-btn:hover { color: var(--text-primary); }
</style>
