// VERTEBR — composables/useBluetooth.js
import { storeToRefs } from 'pinia';
import { useBluetoothStore } from '@/stores/bluetooth.store.js';

export function useBluetooth() {
  const store = useBluetoothStore();
  const { devices, status, loading, connectedDevices, pairedDevices } = storeToRefs(store);
  return {
    devices, status, loading, connectedDevices, pairedDevices,
    load:       () => store.load(),
    setPower:   (v) => store.setPower(v),
    connect:    (addr) => store.connect(addr),
    disconnect: (addr) => store.disconnect(addr),
    pair:       (addr) => store.pair(addr),
    remove:     (addr) => store.remove(addr),
  };
}
