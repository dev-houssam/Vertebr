// VERTEBR — services/display/display.service.js
import { vertebrClient } from '@/services/api/vertebr-client';

class DisplayService {
  async listDisplays()                       { return vertebrClient.call('display:list'); }
  async setMode(display, resolution, refresh){ return vertebrClient.call('display:mode',     { display, resolution, refresh }); }
  async setRotation(display, rotation)       { return vertebrClient.call('display:rotation', { display, rotation }); }
}
export const displayService = new DisplayService();
