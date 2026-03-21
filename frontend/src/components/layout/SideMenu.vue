<template>
  <aside class="sidebar glass-sm">
    <!-- Search -->
    <div class="sidebar-search">
      <div class="search-wrap">
        <svg class="search-icon" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
        </svg>
        <input v-model="query" class="input" placeholder="Rechercher…" type="search" />
      </div>
    </div>

    <!-- Navigation Groups -->
    <nav class="sidebar-nav">
      <template v-for="group in filteredGroups" :key="group.id">
        <div class="nav-group-label">{{ group.label }}</div>
        <router-link
          v-for="route in group.routes"
          :key="route.name"
          :to="route.path"
          custom
          v-slot="{ isActive, navigate }"
        >
          <div class="nav-item" :class="{ active: isActive }" @click="navigate">
            <span class="nav-icon" v-html="ICONS[route.meta.icon] || ICONS.default"></span>
            <span class="nav-label">{{ route.meta.title }}</span>
          </div>
        </router-link>
      </template>
    </nav>

    <!-- Footer -->
    <div class="sidebar-footer">
      <!-- Battery -->
      <div v-if="powerStore.status.has_battery" class="battery-row">
        <div class="battery-shell">
          <div
            class="battery-fill"
            :class="batteryClass"
            :style="{ width: powerStore.status.battery_percent + '%' }"
          ></div>
        </div>
        <span class="text-sm text-muted">{{ powerStore.status.battery_percent }}%</span>
        <span v-if="powerStore.status.time_remaining" class="text-sm text-tertiary truncate">
          &nbsp;·&nbsp;{{ powerStore.status.time_remaining }}
        </span>
      </div>

      <!-- Theme toggle -->
      <button class="btn btn-ghost btn-sm w-full" style="justify-content:flex-start;gap:8px" @click="toggleTheme">
        <span v-html="themeStore.isDark ? ICONS.moon : ICONS.sun"></span>
        {{ themeStore.isDark ? 'Mode sombre' : 'Mode clair' }}
      </button>
    </div>
  </aside>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { menuRoutes }    from '@/router/routes.js';
import { useThemeStore } from '@/stores/theme.store.js';
import { usePowerStore } from '@/stores/power.store.js';

const themeStore = useThemeStore();
const powerStore = usePowerStore();
const query      = ref('');

onMounted(() => powerStore.load());

const ICONS = {
  dashboard: `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>`,
  wifi:      `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1" fill="currentColor"/></svg>`,
  bluetooth: `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5"/></svg>`,
  volume:    `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg>`,
  monitor:   `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>`,
  battery:   `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="6" width="18" height="12" rx="2"/><line x1="23" y1="11" x2="23" y2="13"/></svg>`,
  palette:   `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="13.5" cy="6.5" r="1" fill="currentColor"/><circle cx="17.5" cy="10.5" r="1" fill="currentColor"/><circle cx="8.5" cy="7.5" r="1" fill="currentColor"/><circle cx="6.5" cy="12.5" r="1" fill="currentColor"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/></svg>`,
  shield:    `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>`,
  server:    `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2"/><rect x="2" y="14" width="20" height="8" rx="2"/><line x1="6" y1="6" x2="6.01" y2="6"/><line x1="6" y1="18" x2="6.01" y2="18"/></svg>`,
  moon:      `<svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/></svg>`,
  sun:       `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"/></svg>`,
  default:   `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/></svg>`,
};

const groups = [
  { id: 'main',        label: 'Principal',     routes: menuRoutes.filter(r => r.meta.group === 'main') },
  { id: 'network',     label: 'Réseau',        routes: menuRoutes.filter(r => r.meta.group === 'network') },
  { id: 'system',      label: 'Système',       routes: menuRoutes.filter(r => r.meta.group === 'system') },
  { id: 'personalize', label: 'Personnaliser', routes: menuRoutes.filter(r => r.meta.group === 'personalize') },
  { id: 'advanced',    label: 'Avancé',        routes: menuRoutes.filter(r => r.meta.group === 'advanced') },
];

const filteredGroups = computed(() => {
  const q = query.value.toLowerCase().trim();
  if (!q) return groups.filter(g => g.routes.length > 0);
  return groups
    .map(g => ({ ...g, routes: g.routes.filter(r => r.meta.title.toLowerCase().includes(q)) }))
    .filter(g => g.routes.length > 0);
});

const batteryClass = computed(() => {
  const p = powerStore.status.battery_percent;
  if (p <= 15) return 'low';
  if (p <= 35) return 'medium';
  return 'good';
});

function toggleTheme() {
  themeStore.setMode(themeStore.isDark ? 'light' : 'dark');
}
</script>

<style scoped>
.sidebar {
  width:          220px;
  flex-shrink:    0;
  display:        flex;
  flex-direction: column;
  border-right:   1px solid var(--card-border);
  border-radius:  0;
  padding:        14px 10px;
  overflow:       hidden;
}

.sidebar-search           { margin-bottom: 14px; }
.sidebar-search .input    { font-size: 12px; padding: 7px 12px 7px 32px; }

.sidebar-nav   { flex: 1; overflow-y: auto; overflow-x: hidden; }

.nav-group-label {
  font-size:      10px;
  font-weight:    600;
  letter-spacing: 0.7px;
  text-transform: uppercase;
  color:          var(--text-tertiary);
  padding:        10px 8px 4px;
}

.nav-item {
  display:       flex;
  align-items:   center;
  gap:           9px;
  padding:       8px 10px;
  border-radius: var(--radius-md);
  cursor:        pointer;
  transition:    var(--transition);
  color:         var(--text-secondary);
  font-size:     13px;
  user-select:   none;
}
.nav-item:hover          { background: var(--card-bg-hover); color: var(--text-primary); }
.nav-item.active         { background: var(--accent-dim); color: var(--accent); font-weight: 500; }

.nav-icon                { display: flex; align-items: center; opacity: .6; flex-shrink: 0; transition: var(--transition); }
.nav-item:hover .nav-icon,
.nav-item.active .nav-icon { opacity: 1; }

.nav-label               { flex: 1; }

.sidebar-footer {
  padding-top:    10px;
  border-top:     1px solid var(--card-border);
  margin-top:     8px;
  display:        flex;
  flex-direction: column;
  gap:            6px;
}

.battery-row   { display: flex; align-items: center; gap: 6px; padding: 4px; }

.battery-shell {
  width:         30px;
  height:        13px;
  border:        1.5px solid var(--text-tertiary);
  border-radius: 3px;
  padding:       2px;
  position:      relative;
  flex-shrink:   0;
}
.battery-shell::after {
  content:    '';
  position:   absolute;
  right:      -5px; top: 50%;
  transform:  translateY(-50%);
  width:      3px; height: 6px;
  background: var(--text-tertiary);
  border-radius: 0 2px 2px 0;
}

.battery-fill          { height: 100%; border-radius: 2px; transition: var(--transition); }
.battery-fill.good     { background: var(--success); }
.battery-fill.medium   { background: var(--warning); }
.battery-fill.low      { background: var(--danger); animation: blink 1.5s infinite; }

@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: .4; } }
</style>
