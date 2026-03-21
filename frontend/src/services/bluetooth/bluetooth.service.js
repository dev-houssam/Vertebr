// VERTEBR — services/bluetooth/bluetooth.service.js
import { vertebrClient } from '@/services/api/vertebr-client';

class BluetoothService {
  async getStatus()            { return vertebrClient.call('bluetooth:status'); }
  async listDevices()          { return vertebrClient.call('bluetooth:list'); }
  async setPower(enabled)      { return vertebrClient.call('bluetooth:power',      { enabled }); }
  async connect(address)       { return vertebrClient.call('bluetooth:connect',    { address }); }
  async disconnect(address)    { return vertebrClient.call('bluetooth:disconnect', { address }); }
  async pair(address)          { return vertebrClient.call('bluetooth:pair',       { address }); }
  async remove(address)        { return vertebrClient.call('bluetooth:remove',     { address }); }
}

export const bluetoothService = new BluetoothService();
