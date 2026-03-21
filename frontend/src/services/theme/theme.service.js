// VERTEBR — services/theme/theme.service.js
import { vertebrClient } from '@/services/api/vertebr-client';

class ThemeService {
  async getSystemTheme()  { return vertebrClient.call('theme:get'); }
  async setTheme(params)  { return vertebrClient.call('theme:set', params); }
  async listThemes()      { return vertebrClient.call('theme:list'); }

  /**
   * Écoute les changements de thème système (polling)
   * @param {function} callback - appelé avec le nouveau thème
   * @returns {function} cleanup - appeler pour arrêter le polling
   */
  watchTheme(callback) {
    let lastSnapshot = null;
    const interval = setInterval(async () => {
      const res = await vertebrClient.call('theme:get');
      if (res.status !== 'success') return;
      const snapshot = JSON.stringify(res.data);
      if (snapshot !== lastSnapshot) {
        lastSnapshot = snapshot;
        if (lastSnapshot !== null) callback(res.data); // Skip first call (init)
        lastSnapshot = snapshot;
      }
    }, 3000);
    return () => clearInterval(interval);
  }
}

export const themeService = new ThemeService();
