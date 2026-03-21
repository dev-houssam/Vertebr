<template>
  <div class="caps-view">
    <div class="section-header">
      <div>
        <h1 class="section-title">CAPABILITIES Linux</h1>
        <p class="section-subtitle">Gérer les privilèges fins des binaires système</p>
      </div>
    </div>

    <div class="glass info-box mt-0">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--warning)" stroke-width="2">
        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
      </svg>
      <span class="text-sm">Les modifications CAPABILITIES affectent la sécurité du système. Cette fonctionnalité requiert <strong>CAP_SYS_ADMIN</strong>.</span>
    </div>

    <!-- Binary inspector -->
    <div class="glass section-card mt-16">
      <h3 class="card-title">Inspecter un binaire</h3>
      <div class="flex gap-8">
        <input v-model="binaryPath" class="input" placeholder="/usr/bin/ping" @keyup.enter="inspect" />
        <button class="btn btn-primary" @click="inspect" :disabled="!binaryPath || inspecting">
          <span v-if="inspecting" class="spinner" style="width:12px;height:12px;border-width:1.5px;border-color:rgba(255,255,255,0.3);border-top-color:#fff"></span>
          Inspecter
        </button>
      </div>

      <transition name="slide-up">
        <div v-if="currentBinary" class="binary-result mt-16">
          <div class="binary-path">{{ currentBinary.binary }}</div>
          <div v-if="currentBinary.capabilities.length" class="caps-list mt-8">
            <span v-for="cap in currentBinary.capabilities" :key="cap" class="badge badge-warning">{{ cap }}</span>
          </div>
          <p v-else class="text-sm text-muted mt-8">Aucune CAPABILITY définie sur ce binaire.</p>
          <div class="binary-actions mt-12 flex gap-8">
            <button class="btn btn-danger btn-sm" @click="revoke" v-if="currentBinary.capabilities.length">Révoquer tout</button>
          </div>
        </div>
      </transition>
    </div>

    <!-- Grant capabilities -->
    <div class="glass section-card mt-16" v-if="currentBinary">
      <h3 class="card-title">Accorder des CAPABILITIES</h3>
      <div class="caps-grid">
        <div v-for="cap in capsStore.capabilities" :key="cap.name"
          class="cap-item" :class="{selected: selectedCaps.has(cap.name)}"
          @click="toggleCap(cap.name)">
          <div class="cap-checkbox">
            <svg v-if="selectedCaps.has(cap.name)" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
          </div>
          <div class="cap-info">
            <div class="cap-name text-sm font-medium">{{ cap.name }}</div>
            <div class="cap-desc text-sm text-tertiary">{{ cap.description }}</div>
          </div>
        </div>
      </div>
      <button class="btn btn-primary mt-16" @click="grant" :disabled="!selectedCaps.size || granting">
        <span v-if="granting" class="spinner" style="width:12px;height:12px;border-width:1.5px;border-color:rgba(255,255,255,0.3);border-top-color:#fff"></span>
        Accorder les {{ selectedCaps.size }} CAPABILITIES sélectionnées
      </button>
      <p v-if="grantMsg" class="text-sm mt-8" :class="grantMsg.type === 'success' ? 'text-success' : 'text-danger'">{{ grantMsg.text }}</p>
    </div>
  </div>
</template>
<script setup>
import { ref, reactive, onMounted } from 'vue';
import { useCapsStore } from '@/stores/caps.store.js';
const capsStore  = useCapsStore();
onMounted(() => capsStore.load());

const binaryPath   = ref('');
const inspecting   = ref(false);
const currentBinary = ref(null);
const selectedCaps = reactive(new Set());
const granting     = ref(false);
const grantMsg     = ref(null);

async function inspect() {
  if (!binaryPath.value) return;
  inspecting.value = true;
  const res = await capsStore.getBinaryCaps(binaryPath.value);
  if (res.status === 'success') currentBinary.value = res.data;
  inspecting.value = false;
}

function toggleCap(name) {
  if (selectedCaps.has(name)) selectedCaps.delete(name);
  else selectedCaps.add(name);
}

async function grant() {
  granting.value = true; grantMsg.value = null;
  const res = await capsStore.grant(binaryPath.value, [...selectedCaps]);
  grantMsg.value = { type: res.status, text: res.status === 'success' ? res.message : res.error };
  granting.value = false;
  if (res.status === 'success') { selectedCaps.clear(); await inspect(); }
}

async function revoke() {
  const res = await capsStore.revoke(binaryPath.value);
  if (res.status === 'success') await inspect();
}
</script>
<style scoped>
.caps-view { max-width: 680px; }
.section-card { padding: 20px; }
.card-title   { font-size: 13px; font-weight: 600; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.6px; margin-bottom: 16px; }
.info-box { display: flex; align-items: flex-start; gap: 10px; padding: 14px 16px; border-left: 3px solid var(--warning); background: rgba(245,166,35,0.08); }
.binary-result { padding: 16px; background: var(--card-bg); border-radius: var(--radius-md); border: 1px solid var(--card-border); }
.binary-path { font-family: var(--font-mono); font-size: 13px; color: var(--accent); }
.caps-list { display: flex; flex-wrap: wrap; gap: 6px; }
.caps-grid { display: flex; flex-direction: column; gap: 2px; }
.cap-item  { display: flex; align-items: flex-start; gap: 10px; padding: 10px 12px; border-radius: var(--radius-sm); cursor: pointer; transition: var(--transition); }
.cap-item:hover   { background: var(--card-bg-hover); }
.cap-item.selected { background: var(--accent-dim); }
.cap-checkbox { width: 16px; height: 16px; border-radius: 4px; border: 1.5px solid var(--card-border); flex-shrink: 0; margin-top: 2px; display: flex; align-items: center; justify-content: center; transition: var(--transition); }
.cap-item.selected .cap-checkbox { background: var(--accent); border-color: var(--accent); }
.cap-info { flex: 1; }
.cap-name { font-family: var(--font-mono); }
.cap-desc { line-height: 1.4; margin-top: 2px; }
</style>
