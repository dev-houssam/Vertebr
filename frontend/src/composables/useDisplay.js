// VERTEBR — composables/useDisplay.js
// Auteur : Houssam | Licence : MIT
import { storeToRefs } from 'pinia';
import { useDisplayStore } from '@/stores/display.store.js';

export function useDisplay() {
  const store = useDisplayStore();
  const { displays, loading } = storeToRefs(store);
  return {
    displays, loading,
    load:        ()                           => store.load(),
    setMode:     (display, res, rate)         => store.setMode(display, res, rate),
    setRotation: (display, rotation)          => store.setRotation(display, rotation),
  };
}
