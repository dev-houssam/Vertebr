<template>
  <div class="system-view">
    <div class="section-header">
      <div>
        <h1 class="section-title">Système</h1>
        <p class="section-subtitle">Informations système, fuseau horaire et paramètres régionaux</p>
      </div>
      <button class="btn btn-ghost btn-sm" @click="load">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/>
        </svg>
        Actualiser
      </button>
    </div>

    <!-- Loading skeleton -->
    <div v-if="loading" class="skeleton-group">
      <div class="skeleton" style="height:120px;border-radius:var(--radius-lg)"></div>
      <div class="skeleton" style="height:200px;border-radius:var(--radius-lg)"></div>
    </div>

    <template v-else>
      <!-- System Info Card -->
      <div class="glass info-card" v-if="sysInfo">
        <div class="info-header">
          <div class="os-logo">🐧</div>
          <div>
            <div class="os-name">{{ sysInfo.os_name }}</div>
            <div class="text-sm text-muted">Kernel {{ sysInfo.kernel }} · {{ sysInfo.architecture }}</div>
          </div>
        </div>
        <div class="info-grid">
          <div class="info-item">
            <span class="info-label">Nom d'hôte</span>
            <div class="info-value-row">
              <span v-if="!editingHostname" class="info-value font-mono">{{ sysInfo.hostname }}</span>
              <input v-else v-model="newHostname" class="input" style="width:200px;padding:4px 10px;font-size:13px" @keyup.enter="applyHostname" @keyup.escape="editingHostname=false" autofocus />
              <button v-if="!editingHostname" class="btn btn-ghost btn-sm" @click="startEditHostname">Modifier</button>
              <template v-else>
                <button class="btn btn-primary btn-sm" @click="applyHostname" :disabled="saving">Enregistrer</button>
                <button class="btn btn-ghost btn-sm" @click="editingHostname=false">Annuler</button>
              </template>
            </div>
          </div>
          <div class="info-item">
            <span class="info-label">Temps de fonctionnement</span>
            <span class="info-value">{{ sysInfo.uptime }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Locale</span>
            <span class="info-value font-mono text-sm">{{ sysInfo.locale }}</span>
          </div>
        </div>
      </div>

      <!-- Timezone Card -->
      <div class="glass section-card mt-16" v-if="tzInfo">
        <h3 class="card-title">Fuseau horaire</h3>

        <div class="tz-row">
          <div class="tz-current">
            <div class="tz-name">{{ tzInfo.current }}</div>
            <div class="text-sm text-muted">UTC{{ tzInfo.utc_offset }}</div>
          </div>
          <div class="flex gap-8">
            <span class="badge" :class="tzInfo.ntp_sync ? 'badge-success' : 'badge-warning'">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor">
                <circle cx="12" cy="12" r="10" opacity=".3"/>
                <circle cx="12" cy="12" r="5"/>
              </svg>
              NTP {{ tzInfo.ntp_sync ? 'synchronisé' : 'non synchronisé' }}
            </span>
            <label class="toggle">
              <input type="checkbox" :checked="tzInfo.ntp_sync" @change="e => setNtp(e.target.checked)" />
              <div class="toggle-track"></div>
              <div class="toggle-thumb"></div>
            </label>
          </div>
        </div>

        <div class="divider"></div>

        <!-- Timezone search + list -->
        <div class="tz-search-wrap">
          <div class="search-wrap" style="margin-bottom:10px">
            <svg class="search-icon" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
            </svg>
            <input v-model="tzQuery" class="input" placeholder="Chercher un fuseau (ex: Europe/Paris)…" />
          </div>
          <div class="tz-list">
            <div
              v-for="tz in filteredTimezones"
              :key="tz"
              class="tz-item"
              :class="{ selected: tz === tzInfo.current }"
              @click="setTimezone(tz)"
            >
              <span>{{ tz }}</span>
              <svg v-if="tz === tzInfo.current" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="3">
                <polyline points="20 6 9 17 4 12"/>
              </svg>
            </div>
            <div v-if="!filteredTimezones.length" class="text-sm text-muted" style="padding:12px 8px">
              Aucun résultat pour « {{ tzQuery }} »
            </div>
          </div>
        </div>
      </div>

      <!-- Current User Card -->
      <div class="glass section-card mt-16" v-if="userInfo">
        <h3 class="card-title">Utilisateur courant</h3>
        <div class="user-row">
          <div class="user-avatar">{{ userInfo.username.charAt(0).toUpperCase() }}</div>
          <div class="user-details">
            <div class="font-semi" style="font-size:16px">{{ userInfo.username }}</div>
            <div class="text-sm text-muted">UID {{ userInfo.uid }} · GID {{ userInfo.gid }}</div>
            <div class="text-sm text-muted font-mono">{{ userInfo.home }}</div>
          </div>
        </div>
        <div class="divider"></div>
        <div class="groups-section">
          <div class="text-sm text-muted" style="margin-bottom:8px">Groupes :</div>
          <div class="groups-list">
            <span v-for="g in userInfo.groups" :key="g" class="badge badge-muted">{{ g }}</span>
          </div>
        </div>
      </div>
    </template>

    <!-- Success/Error toast -->
    <transition name="slide-up">
      <div v-if="toast" class="toast" :class="toast.type">
        {{ toast.message }}
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { vertebrClient } from '@/services/api/vertebr-client';

const loading         = ref(true);
const sysInfo         = ref(null);
const tzInfo          = ref(null);
const allTimezones    = ref([]);
const userInfo        = ref(null);
const tzQuery         = ref('');
const editingHostname = ref(false);
const newHostname     = ref('');
const saving          = ref(false);
const toast           = ref(null);

const filteredTimezones = computed(() => {
  if (!tzQuery.value) return allTimezones.value.slice(0, 80);
  const q = tzQuery.value.toLowerCase();
  return allTimezones.value.filter(t => t.toLowerCase().includes(q)).slice(0, 80);
});

async function load() {
  loading.value = true;
  const [infoRes, tzRes, tzsRes, userRes] = await Promise.all([
    vertebrClient.call('system:info'),
    vertebrClient.call('system:timezone'),
    vertebrClient.call('system:timezones'),
    vertebrClient.call('system:user'),
  ]);
  if (infoRes.status  === 'success') sysInfo.value        = infoRes.data;
  if (tzRes.status    === 'success') tzInfo.value         = tzRes.data;
  if (tzsRes.status   === 'success') allTimezones.value   = tzsRes.data;
  if (userRes.status  === 'success') userInfo.value       = userRes.data;
  loading.value = false;
}

function startEditHostname() {
  newHostname.value  = sysInfo.value?.hostname || '';
  editingHostname.value = true;
}

async function applyHostname() {
  saving.value = true;
  const res = await vertebrClient.call('system:set_hostname', { hostname: newHostname.value });
  if (res.status === 'success') {
    sysInfo.value.hostname = newHostname.value;
    editingHostname.value  = false;
    showToast('success', `Nom d'hôte changé en « ${newHostname.value} »`);
  } else {
    showToast('error', res.error || 'Erreur lors du changement');
  }
  saving.value = false;
}

async function setTimezone(tz) {
  const res = await vertebrClient.call('system:set_timezone', { timezone: tz });
  if (res.status === 'success') {
    const reload = await vertebrClient.call('system:timezone');
    if (reload.status === 'success') tzInfo.value = reload.data;
    showToast('success', `Fuseau horaire : ${tz}`);
  } else {
    showToast('error', res.error);
  }
}

async function setNtp(enabled) {
  const res = await vertebrClient.call('system:set_ntp', { enabled });
  if (res.status === 'success') {
    if (tzInfo.value) tzInfo.value.ntp_sync = enabled;
    showToast('success', `NTP ${enabled ? 'activé' : 'désactivé'}`);
  } else {
    showToast('error', res.error);
  }
}

function showToast(type, message) {
  toast.value = { type, message };
  setTimeout(() => { toast.value = null; }, 3000);
}

onMounted(load);
</script>

<style scoped>
.system-view  { max-width: 680px; position: relative; }

/* Info card */
.info-card    { padding: 20px; }
.info-header  { display: flex; align-items: center; gap: 16px; margin-bottom: 20px; }
.os-logo      { font-size: 36px; width: 56px; height: 56px; display: flex; align-items: center; justify-content: center; background: var(--card-bg-hover); border-radius: var(--radius-md); }
.os-name      { font-size: 18px; font-weight: 600; }
.info-grid    { display: flex; flex-direction: column; gap: 14px; }
.info-item    { display: flex; align-items: center; justify-content: space-between; gap: 16px; }
.info-label   { font-size: 13px; color: var(--text-secondary); flex-shrink: 0; }
.info-value   { font-size: 13px; font-weight: 500; }
.info-value-row { display: flex; align-items: center; gap: 8px; }
.font-mono    { font-family: var(--font-mono); font-size: 12px; }

/* Section card */
.section-card  { padding: 20px; }
.card-title    { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.7px; color: var(--text-tertiary); margin-bottom: 16px; }

/* Timezone */
.tz-row        { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 12px; }
.tz-name       { font-size: 18px; font-weight: 600; font-family: var(--font-mono); }
.tz-list       { max-height: 200px; overflow-y: auto; border: 1px solid var(--card-border); border-radius: var(--radius-md); }
.tz-item       { display: flex; align-items: center; justify-content: space-between; padding: 8px 14px; font-size: 13px; font-family: var(--font-mono); cursor: pointer; transition: var(--transition); }
.tz-item:hover    { background: var(--card-bg-hover); }
.tz-item.selected { background: var(--accent-dim); color: var(--accent); }

/* User */
.user-row     { display: flex; align-items: center; gap: 14px; }
.user-avatar  { width: 48px; height: 48px; border-radius: 50%; background: var(--accent-gradient); display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: 600; color: #fff; flex-shrink: 0; }
.user-details { display: flex; flex-direction: column; gap: 3px; }
.groups-section { }
.groups-list  { display: flex; flex-wrap: wrap; gap: 6px; }

/* Skeleton */
.skeleton-group { display: flex; flex-direction: column; gap: 16px; }

/* Toast */
.toast {
  position:      fixed;
  bottom:        24px;
  right:         32px;
  padding:       10px 18px;
  border-radius: var(--radius-xl);
  font-size:     13px;
  font-weight:   500;
  z-index:       2000;
  box-shadow:    var(--shadow-md);
}
.toast.success { background: rgba(61,214,140,0.15); color: var(--success); border: 1px solid rgba(61,214,140,0.3); }
.toast.error   { background: rgba(255,92,92,0.15);  color: var(--danger);  border: 1px solid rgba(255,92,92,0.3); }
</style>
