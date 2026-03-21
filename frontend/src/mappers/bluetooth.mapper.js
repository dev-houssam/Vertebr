// VERTEBR — mappers/bluetooth.mapper.js
// Auteur : Houssam | Licence : MIT
import { BluetoothDevice } from '@/models/bluetooth/Device.js';

export const bluetoothMapper = {
  toModel(dto) {
    if (!dto) return null;
    return new BluetoothDevice(dto);
  },
  toModelList(dtos) {
    return (dtos ?? []).map(dto => this.toModel(dto));
  },
};
