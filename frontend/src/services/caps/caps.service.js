// VERTEBR — services/caps/caps.service.js
import { vertebrClient } from '@/services/api/vertebr-client';

class CapsService {
  async listCapabilities()              { return vertebrClient.call('caps:list'); }
  async getBinaryCaps(binary)           { return vertebrClient.call('caps:get',    { binary }); }
  async grant(binary, capabilities)     { return vertebrClient.call('caps:grant',  { binary, capabilities }); }
  async revoke(binary)                  { return vertebrClient.call('caps:revoke', { binary }); }
}
export const capsService = new CapsService();
