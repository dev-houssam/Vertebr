// VERTEBR — services/system/system.service.js
// Auteur : Houssam | Licence : MIT
import { vertebrClient } from '@/services/api/vertebr-client';

class SystemService {
  async getInfo()                  { return vertebrClient.call('system:info'); }
  async getTimezone()              { return vertebrClient.call('system:timezone'); }
  async listTimezones()            { return vertebrClient.call('system:timezones'); }
  async getCurrentUser()           { return vertebrClient.call('system:user'); }
  async setHostname(hostname)      { return vertebrClient.call('system:set_hostname', { hostname }); }
  async setTimezone(timezone)      { return vertebrClient.call('system:set_timezone', { timezone }); }
  async setNtp(enabled)            { return vertebrClient.call('system:set_ntp',      { enabled }); }
  async setLocale(locale)          { return vertebrClient.call('system:set_locale',   { locale }); }
}

export const systemService = new SystemService();
