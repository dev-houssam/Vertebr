// VERTEBR — services/wifi/wifi.service.js
// Couche service Wi-Fi côté frontend
// Auteur : Houssam | Licence : MIT
import { vertebrClient } from '@/services/api/vertebr-client';

class WifiService {
  async listNetworks()              { return vertebrClient.call('wifi:list'); }
  async getStatus()                 { return vertebrClient.call('wifi:status'); }
  async connect(ssid, password)     { return vertebrClient.call('wifi:connect',  { ssid, password }); }
  async disconnect()                { return vertebrClient.call('wifi:disconnect'); }
  async setEnabled(enabled)         { return vertebrClient.call('wifi:enabled',  { enabled }); }
  async setAirplaneMode(enabled)    { return vertebrClient.call('wifi:airplane', { enabled }); }
  async forgetNetwork(ssid)         { return vertebrClient.call('wifi:forget',   { ssid }); }
}

export const wifiService = new WifiService();
