<template>
  <div class="display-view">
    <div class="section-header">
      <div><h1 class="section-title">Affichage</h1><p class="section-subtitle">Résolution, taux de rafraîchissement et orientation</p></div>
      <button class="btn btn-ghost btn-sm" @click="displayStore.load()">Actualiser</button>
    </div>

    <div v-if="displayStore.loading" class="flex-center" style="padding:60px">
      <div class="spinner"></div>
    </div>

    <div v-else v-for="display in displayStore.displays" :key="display.name" class="glass display-card mt-16">
      <div class="display-header">
        <div class="flex gap-12" style="align-items:center">
          <div class="icon-box" style="background:var(--accent-dim)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2">
              <rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/>
            </svg>
          </div>
          <div>
            <div class="font-medium">{{ display.name }}</div>
            <div class="text-sm text-muted">{{ display.current_mode }} {{ display.primary ? '· Principal' : '' }}</div>
          </div>
        </div>
        <span v-if="display.primary" class="badge badge-accent">Principal</span>
      </div>

      <div class="divider"></div>

      <!-- Resolution select -->
      <div class="setting-row">
        <label class="setting-label">Résolution</label>
        <select class="input" style="width:200px" :value="selectedRes[display.name]"
          @change="e => { selectedRes[display.name] = e.target.value; }">
          <option v-for="mode in display.modes" :key="mode.resolution" :value="mode.resolution">
            {{ mode.resolution }}{{ mode.preferred ? ' (recommandée)' : '' }}
          </option>
        </select>
      </div>

      <!-- Refresh rate -->
      <div class="setting-row" v-if="currentMode(display)">
        <label class="setting-label">Taux de rafraîchissement</label>
        <select class="input" style="width:140px" :value="selectedRate[display.name]"
          @change="e => selectedRate[display.name] = Number(e.target.value)">
          <option v-for="rate in currentMode(display).refresh_rates" :key="rate" :value="rate">
            {{ rate }} Hz
          </option>
        </select>
      </div>

      <!-- Rotation -->
      <div class="setting-row">
        <label class="setting-label">Orientation</label>
        <div class="rotation-chips">
          <div v-for="rot in rotations" :key="rot.id"
            class="rot-chip" :class="{selected: (selectedRot[display.name] || display.rotation) === rot.id}"
            @click="selectedRot[display.name] = rot.id">
            {{ rot.label }}
          </div>
        </div>
      </div>

      <div class="divider"></div>
      <div class="flex" style="justify-content:flex-end;padding:0 0 4px">
        <button class="btn btn-primary" @click="applySettings(display)">Appliquer</button>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted } from 'vue';
import { useDisplayStore } from '@/stores/display.store.js';
const displayStore = useDisplayStore();
onMounted(() => displayStore.load());

const selectedRes  = ref({});
const selectedRate = ref({});
const selectedRot  = ref({});

const rotations = [
  { id: 'normal',   label: '0°' },
  { id: 'right',    label: '90°' },
  { id: 'inverted', label: '180°' },
  { id: 'left',     label: '270°' },
];

function currentMode(display) {
  const res = selectedRes.value[display.name] || display.current_mode;
  return display.modes.find(m => m.resolution === res);
}

async function applySettings(display) {
  const res  = selectedRes.value[display.name]  || display.current_mode;
  const rate = selectedRate.value[display.name] || null;
  const rot  = selectedRot.value[display.name]  || display.rotation;
  if (rot !== display.rotation) {
    await displayStore.setRotation(display.name, rot);
  }
  if (res) {
    await displayStore.setMode(display.name, res, rate);
  }
  await displayStore.load();
}
</script>
<style scoped>
.display-view { max-width: 680px; }
.display-card { padding: 20px; }
.display-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
.setting-row  { display: flex; align-items: center; justify-content: space-between; padding: 10px 0; }
.setting-label { font-size: 14px; font-weight: 500; }
.rotation-chips { display: flex; gap: 6px; }
.rot-chip  { padding: 5px 12px; border-radius: var(--radius-xl); background: var(--card-bg); border: 1px solid var(--card-border); font-size: 12px; cursor: pointer; transition: var(--transition); }
.rot-chip:hover   { background: var(--card-bg-hover); }
.rot-chip.selected { background: var(--accent-dim); border-color: var(--accent); color: var(--accent); }
</style>
