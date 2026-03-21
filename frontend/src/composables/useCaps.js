// VERTEBR — composables/useCaps.js
// Auteur : Houssam | Licence : MIT
import { storeToRefs } from 'pinia';
import { useCapsStore } from '@/stores/caps.store.js';

export function useCaps() {
  const store = useCapsStore();
  const { capabilities, loading, error } = storeToRefs(store);
  return {
    capabilities, loading, error,
    load:           ()                       => store.load(),
    getBinaryCaps:  (binary)                 => store.getBinaryCaps(binary),
    grant:          (binary, caps)           => store.grant(binary, caps),
    revoke:         (binary)                 => store.revoke(binary),
  };
}
