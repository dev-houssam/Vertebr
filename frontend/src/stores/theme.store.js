// VERTEBR — stores/theme.store.js
// Store de thème dynamique (HarmonyOS + GTK system theme)
// Auteur : Houssam | Licence : MIT

import { defineStore } from 'pinia';
import { vertebrClient } from '@/services/api/vertebr-client';

export const useThemeStore = defineStore('theme', {
  state: () => ({
    mode:         'dark',      // 'dark' | 'light'
    accentColor:  '#4da3ff',
    gtkTheme:     'Pop-dark',
    iconTheme:    'Pop',
    fontName:     'Fira Sans 11',
    cursorTheme:  'Pop',
    systemDetected: false,
    followSystem:   true,
    availableThemes: [],
  }),

  getters: {
    isDark: (s) => s.mode === 'dark',

    cssVars: (state) => {
      const dark = state.mode === 'dark';
      return {
        '--bg':             dark ? '#0b0d11'                            : '#f0f2f7',
        '--bg-secondary':   dark ? '#0f1115'                            : '#e8eaf0',
        '--card-bg':        dark ? 'rgba(255,255,255,0.04)'             : 'rgba(255,255,255,0.75)',
        '--card-bg-hover':  dark ? 'rgba(255,255,255,0.07)'             : 'rgba(255,255,255,0.92)',
        '--card-border':    dark ? 'rgba(255,255,255,0.07)'             : 'rgba(0,0,0,0.08)',
        '--sidebar-bg':     dark ? 'rgba(255,255,255,0.025)'            : 'rgba(255,255,255,0.6)',
        '--text-primary':   dark ? '#f0f1f5'                            : '#111218',
        '--text-secondary': dark ? '#8a8fa8'                            : '#5a5f75',
        '--text-tertiary':  dark ? '#555a72'                            : '#9098b0',
        '--accent':         state.accentColor,
        '--accent-dim':     dark ? 'rgba(77,163,255,0.15)'              : 'rgba(77,163,255,0.12)',
        '--accent-gradient':'linear-gradient(135deg, ' + state.accentColor + ', #7f5cff)',
        '--success':        '#3dd68c',
        '--warning':        '#f5a623',
        '--danger':         '#ff5c5c',
        '--shadow-sm':      dark ? '0 4px 16px rgba(0,0,0,0.35)'       : '0 4px 16px rgba(0,0,0,0.1)',
        '--shadow-md':      dark ? '0 8px 32px rgba(0,0,0,0.45)'       : '0 8px 32px rgba(0,0,0,0.14)',
        '--shadow-lg':      dark ? '0 16px 48px rgba(0,0,0,0.6)'       : '0 16px 48px rgba(0,0,0,0.18)',
        '--blur-sm':        'blur(12px)',
        '--blur-md':        'blur(24px)',
        '--blur-lg':        'blur(40px)',
        '--radius-sm':      '12px',
        '--radius-md':      '18px',
        '--radius-lg':      '24px',
        '--radius-xl':      '32px',
        '--font-sans':      '"Fira Sans", "SF Pro Display", system-ui, sans-serif',
        '--font-mono':      '"Fira Code", "JetBrains Mono", monospace',
        '--transition':     'all 0.22s cubic-bezier(0.4, 0, 0.2, 1)',
      };
    },
  },

  actions: {
    async init() {
      await this.detectSystemTheme();
      this.applyTheme();
      this.watchSystemTheme();
    },

    async detectSystemTheme() {
      try {
        const res = await vertebrClient.call('theme:get');
        if (res.status === 'success' && res.data) {
          this.gtkTheme    = res.data.gtk_theme;
          this.iconTheme   = res.data.icon_theme;
          this.fontName    = res.data.font_name;
          this.cursorTheme = res.data.cursor_theme;
          if (this.followSystem) {
            this.mode = res.data.is_dark ? 'dark' : 'light';
          }
          this.systemDetected = true;
        }
      } catch {
        // Fallback dark
        this.mode = 'dark';
      }

      // Charger les thèmes disponibles
      const listRes = await vertebrClient.call('theme:list');
      if (listRes.status === 'success') {
        this.availableThemes = listRes.data;
      }
    },

    watchSystemTheme() {
      // Polling léger toutes les 3s pour détecter les changements système
      setInterval(async () => {
        if (!this.followSystem) return;
        const res = await vertebrClient.call('theme:get');
        if (res.status === 'success' && res.data) {
          const newMode = res.data.is_dark ? 'dark' : 'light';
          if (newMode !== this.mode) {
            this.mode = newMode;
            this.applyTheme();
          }
        }
      }, 3000);
    },

    applyTheme() {
      const root = document.documentElement;
      const vars = this.cssVars;
      Object.entries(vars).forEach(([k, v]) => root.style.setProperty(k, v));
      root.classList.toggle('dark',  this.isDark);
      root.classList.toggle('light', !this.isDark);
    },

    setMode(mode) {
      this.mode = mode;
      this.followSystem = false;
      this.applyTheme();
      vertebrClient.call('theme:set', {
        color_scheme: mode,
        gtk_theme: mode === 'dark' ? this.gtkTheme.replace('-dark', '') + '-dark'
                                   : this.gtkTheme.replace('-dark', ''),
      });
    },

    setAccent(color) {
      this.accentColor = color;
      this.applyTheme();
    },

    async setGtkTheme(theme) {
      this.gtkTheme = theme;
      await vertebrClient.call('theme:set', { gtk_theme: theme });
      this.applyTheme();
    },

    enableFollowSystem() {
      this.followSystem = true;
      this.detectSystemTheme();
    },
  },
});
