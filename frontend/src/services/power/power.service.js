// VERTEBR — services/power/power.service.js
import { vertebrClient } from '@/services/api/vertebr-client';

class PowerService {
  async getStatus()          { return vertebrClient.call('power:status'); }
  async setProfile(profile)  { return vertebrClient.call('power:profile',  { profile }); }
  async reboot()             { return vertebrClient.call('power:reboot'); }
  async shutdown()           { return vertebrClient.call('power:shutdown'); }
  async suspend()            { return vertebrClient.call('power:suspend'); }
}
export const powerService = new PowerService();
