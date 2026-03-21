// VERTEBR — composables/usePower.js
// Auteur : Houssam | Licence : MIT
import { storeToRefs } from 'pinia';
import { usePowerStore } from '@/stores/power.store.js';

export function usePower() {
  const store = usePowerStore();
  const { status, loading } = storeToRefs(store);
  return {
    status, loading,
    load:       ()        => store.load(),
    setProfile: (profile) => store.setProfile(profile),
    reboot:     ()        => store.reboot(),
    shutdown:   ()        => store.shutdown(),
    suspend:    ()        => store.suspend(),
  };
}
