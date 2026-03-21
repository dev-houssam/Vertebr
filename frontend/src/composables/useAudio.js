// VERTEBR — composables/useAudio.js
// Auteur : Houssam | Licence : MIT
import { storeToRefs } from 'pinia';
import { useAudioStore } from '@/stores/audio.store.js';

export function useAudio() {
  const store = useAudioStore();
  const { sinks, sources, loading, defaultSink, defaultSource } = storeToRefs(store);
  return {
    sinks, sources, loading, defaultSink, defaultSource,
    load:       ()                        => store.load(),
    setVolume:  (name, vol, isSink=true)  => store.setVolume(name, vol, isSink),
    setMute:    (name, muted, isSink=true)=> store.setMute(name, muted, isSink),
    setDefault: (name)                    => store.setDefault(name),
  };
}
