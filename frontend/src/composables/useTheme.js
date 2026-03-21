// VERTEBR — composables/useTheme.js
import { storeToRefs } from 'pinia';
import { useThemeStore } from '@/stores/theme.store.js';

export function useTheme() {
  const store = useThemeStore();
  const { mode, isDark, accentColor, gtkTheme, fontName, followSystem, availableThemes } = storeToRefs(store);
  return {
    mode, isDark, accentColor, gtkTheme, fontName, followSystem, availableThemes,
    setMode:           (m) => store.setMode(m),
    setAccent:         (c) => store.setAccent(c),
    setGtkTheme:       (t) => store.setGtkTheme(t),
    enableFollowSystem:()  => store.enableFollowSystem(),
    toggle:            ()  => store.setMode(store.isDark ? 'light' : 'dark'),
  };
}
