<template>
  <div class="power-view">
    <div class="section-header">
      <div><h1 class="section-title">Alimentation</h1><p class="section-subtitle">Batterie, profils et actions système</p></div>
    </div>

    <!-- Battery card -->
    <div v-if="powerStore.status.has_battery" class="glass battery-card">
      <div class="battery-visual">
        <div class="battery-outer">
          <div class="battery-fill" :class="batteryClass" :style="{width: powerStore.status.battery_percent + '%'}"></div>
          <span class="battery-pct">{{ powerStore.status.battery_percent }}%</span>
        </div>
        <div class="battery-tip"></div>
      </div>
      <div class="battery-details">
        <div class="battery-state">{{ powerStore.status.battery_state }}</div>
        <div class="text-sm text-muted" v-if="powerStore.status.time_remaining">
          {{ powerStore.status.on_battery ? 'Temps restant' : 'Plein dans' }}: {{ powerStore.status.time_remaining }}
        </div>
      </div>
    </div>

    <!-- Power profiles -->
    <h2 class="text-lg font-semi mt-24 mb-12">Profil d'alimentation</h2>
    <div class="profiles-grid">
      <div v-for="profile in profiles" :key="profile.id"
        class="profile-card glass card-interactive"
        :class="{selected: powerStore.status.power_profile === profile.id}"
        @click="setProfile(profile.id)">
        <div class="profile-icon" :style="{color: profile.color, background: profile.color + '20'}">
          <span v-html="profile.icon"></span>
        </div>
        <div class="profile-name">{{ profile.name }}</div>
        <div class="profile-desc text-sm text-muted">{{ profile.desc }}</div>
        <div v-if="powerStore.status.power_profile === profile.id" class="profile-check">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="3">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
        </div>
      </div>
    </div>

    <!-- System actions -->
    <h2 class="text-lg font-semi mt-24 mb-12">Actions système</h2>
    <div class="actions-row">
      <button class="action-btn glass card-interactive" @click="confirmAction('suspend')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="1.5">
          <path d="M17.75 4.09l-2.53 1.94.91 3.06-2.63-1.81-2.63 1.81.91-3.06-2.53-1.94 3.17-.08L12 1l1.08 2.97 3.17.12z"/>
          <path d="M8 15.55a5.5 5.5 0 1 0 7.93 7.65A5.5 5.5 0 0 0 8 15.55z"/>
          <path d="M4 6h2M12 2v2M20 6h2M4 18h2M20 18h2"/>
        </svg>
        <span class="action-label">Veille</span>
      </button>
      <button class="action-btn glass card-interactive" @click="confirmAction('reboot')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--warning)" stroke-width="1.5">
          <path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38"/>
        </svg>
        <span class="action-label">Redémarrer</span>
      </button>
      <button class="action-btn glass card-interactive" @click="confirmAction('shutdown')">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--danger)" stroke-width="1.5">
          <path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/>
        </svg>
        <span class="action-label">Éteindre</span>
      </button>
    </div>

    <!-- Confirm modal -->
    <transition name="modal">
      <div v-if="pendingAction" class="modal-overlay" @click.self="pendingAction = null">
        <div class="modal-content glass" style="max-width:360px">
          <div class="modal-header" style="flex-direction:column;gap:8px;align-items:flex-start">
            <h3 class="font-semi">{{ actionLabels[pendingAction]?.title }}</h3>
            <p class="text-sm text-muted">{{ actionLabels[pendingAction]?.desc }}</p>
          </div>
          <div class="modal-footer">
            <button class="btn btn-ghost" @click="pendingAction = null">Annuler</button>
            <button class="btn" :class="actionLabels[pendingAction]?.btnClass" @click="doAction">Confirmer</button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue';
import { usePowerStore } from '@/stores/power.store.js';
const powerStore = usePowerStore();
onMounted(() => powerStore.load());

const pendingAction = ref(null);

const batteryClass = computed(() => {
  const p = powerStore.status.battery_percent;
  if (p <= 15) return 'danger';
  if (p <= 35) return 'warning';
  return 'good';
});

const profiles = [
  { id: 'power-saver',  name: 'Économie',   desc: 'Réduit les performances pour préserver la batterie', color: '#3dd68c', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>` },
  { id: 'balanced',     name: 'Équilibré',  desc: 'Performances et autonomie optimisées automatiquement', color: '#4da3ff', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>` },
  { id: 'performance',  name: 'Performances', desc: 'Performances maximales, consommation accrue', color: '#f5a623', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" fill="currentColor"/></svg>` },
];

const actionLabels = {
  suspend:  { title: 'Mettre en veille ?',    desc: 'Le système sera suspendu.',                   btnClass: 'btn-primary' },
  reboot:   { title: 'Redémarrer le système ?', desc: 'Toutes les applications seront fermées.',   btnClass: 'btn-ghost'   },
  shutdown: { title: 'Éteindre le système ?', desc: 'Toutes les applications seront fermées.',     btnClass: 'btn-danger'  },
};

function confirmAction(action) { pendingAction.value = action; }
async function doAction() {
  const a = pendingAction.value;
  pendingAction.value = null;
  if (a === 'reboot')   await powerStore.reboot();
  if (a === 'shutdown') await powerStore.shutdown();
  if (a === 'suspend')  await powerStore.suspend();
}
async function setProfile(p) { await powerStore.setProfile(p); }
</script>
<style scoped>
.power-view { max-width: 680px; }
.battery-card { padding: 24px; display: flex; align-items: center; gap: 24px; }
.battery-outer { position: relative; width: 160px; height: 32px; border: 2px solid var(--card-border); border-radius: 6px; padding: 3px; }
.battery-tip    { width: 6px; height: 14px; background: var(--card-border); border-radius: 0 3px 3px 0; }
.battery-fill   { height: 100%; border-radius: 3px; transition: var(--transition); }
.battery-fill.good    { background: var(--success); }
.battery-fill.warning { background: var(--warning); }
.battery-fill.danger  { background: var(--danger);  box-shadow: 0 0 8px var(--danger); }
.battery-pct { position: absolute; right: -44px; top: 50%; transform: translateY(-50%); font-size: 12px; font-weight: 500; color: var(--text-primary); }
.battery-state { font-size: 16px; font-weight: 500; }
.profiles-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.profile-card { padding: 18px 16px; position: relative; }
.profile-card.selected { border-color: var(--accent); background: var(--accent-dim); }
.profile-icon { width: 38px; height: 38px; border-radius: var(--radius-sm); display: flex; align-items: center; justify-content: center; margin-bottom: 10px; }
.profile-name { font-weight: 500; margin-bottom: 4px; }
.profile-desc { font-size: 11px; line-height: 1.4; }
.profile-check { position: absolute; top: 12px; right: 12px; width: 20px; height: 20px; background: var(--accent-dim); border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.actions-row { display: flex; gap: 12px; }
.action-btn { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 20px 12px; cursor: pointer; }
.action-label { font-size: 13px; font-weight: 500; }
.modal-header { padding: 20px 20px 0; }
.modal-footer { padding: 16px 20px 20px; display: flex; justify-content: flex-end; gap: 8px; }
</style>
