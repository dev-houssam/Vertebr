// VERTEBR — router/routes.js
// Définition des routes frontend (symétrique routes.toml)
// Auteur : Houssam | Licence : MIT

export const menuRoutes = [
  {
    path:      '/',
    name:      'Dashboard',
    component: () => import('@/views/dashboard/DashboardView.vue'),
    meta: { title: 'Tableau de bord',  icon: 'dashboard', permission: 'user', group: 'main' },
  },
  // Réseau
  {
    path:      '/wifi',
    name:      'Wifi',
    component: () => import('@/views/wifi/WifiView.vue'),
    meta: { title: 'Wi-Fi',            icon: 'wifi',      permission: 'user', group: 'network' },
  },
  {
    path:      '/bluetooth',
    name:      'Bluetooth',
    component: () => import('@/views/bluetooth/BluetoothView.vue'),
    meta: { title: 'Bluetooth',        icon: 'bluetooth', permission: 'user', group: 'network' },
  },
  // Système
  {
    path:      '/audio',
    name:      'Audio',
    component: () => import('@/views/audio/AudioView.vue'),
    meta: { title: 'Son',              icon: 'volume',    permission: 'user', group: 'system'  },
  },
  {
    path:      '/display',
    name:      'Display',
    component: () => import('@/views/display/DisplayView.vue'),
    meta: { title: 'Affichage',        icon: 'monitor',   permission: 'user', group: 'system'  },
  },
  {
    path:      '/power',
    name:      'Power',
    component: () => import('@/views/power/PowerView.vue'),
    meta: { title: 'Alimentation',     icon: 'battery',   permission: 'user', group: 'system'  },
  },
  {
    path:      '/system',
    name:      'System',
    component: () => import('@/views/system/SystemView.vue'),
    meta: { title: 'Système',          icon: 'server',    permission: 'user', group: 'system'  },
  },
  // Personnaliser
  {
    path:      '/theme',
    name:      'Theme',
    component: () => import('@/views/theme/ThemeView.vue'),
    meta: { title: 'Apparence',        icon: 'palette',   permission: 'user', group: 'personalize' },
  },
  // Avancé
  {
    path:      '/caps',
    name:      'Capabilities',
    component: () => import('@/views/caps/CapsView.vue'),
    meta: { title: 'CAPABILITIES',     icon: 'shield',    permission: 'caps', group: 'advanced'    },
  },
];
