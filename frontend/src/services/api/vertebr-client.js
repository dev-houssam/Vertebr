// VERTEBR — services/api/vertebr-client.js
// Client de communication avec le daemon
// Auteur : Houssam | Licence : MIT

class VertebrClient {
  /**
   * Appelle une route du daemon Vertebr
   * @param {string} route
   * @param {object} payload
   * @returns {Promise<{status: 'success'|'error', data?: any, error?: string}>}
   */
  async call(route, payload = {}) {
    if (!window.vertebr) {
      console.warn('Vertebr bridge not available — using mock data');
      return this._mockCall(route, payload);
    }
    return window.vertebr.call(route, payload);
  }

  /**
   * Données mock pour le développement sans daemon
   */
  _mockCall(route, payload) {
    const mocks = {
      'wifi:list': {
        status: 'success',
        data: [
          { name: 'HarmonyNet-5G', bssid: 'AA:BB:CC:DD:EE:FF', connected: true,  signal: 87, secured: true,  security: 'WPA3', frequency: '5 GHz', in_use: true  },
          { name: 'Livebox-A1B2',  bssid: 'BB:CC:DD:EE:FF:00', connected: false, signal: 64, secured: true,  security: 'WPA2', frequency: '2.4 GHz', in_use: false },
          { name: 'eduroam',       bssid: 'CC:DD:EE:FF:00:11', connected: false, signal: 45, secured: true,  security: 'WPA2', frequency: '5 GHz', in_use: false },
          { name: 'CafeWifi',      bssid: 'DD:EE:FF:00:11:22', connected: false, signal: 32, secured: false, security: '--',   frequency: '2.4 GHz', in_use: false },
        ]
      },
      'wifi:status':     { status: 'success', data: { enabled: true,  airplane_mode: false, connected_to: 'HarmonyNet-5G' } },
      'bluetooth:status':{ status: 'success', data: { enabled: true,  discoverable: false, adapter: 'Vertebr BT' } },
      'bluetooth:list':  { status: 'success', data: [
        { address: 'AA:11:22:33:44:55', name: 'WH-1000XM5',   paired: true, connected: true,  trusted: true,  device_type: 'headphones' },
        { address: 'BB:22:33:44:55:66', name: 'MX Keys',      paired: true, connected: false, trusted: true,  device_type: 'keyboard'   },
        { address: 'CC:33:44:55:66:77', name: 'Galaxy Buds2', paired: true, connected: false, trusted: false, device_type: 'headphones' },
      ]},
      'audio:sinks': { status: 'success', data: [
        { index: 0, name: 'alsa_output.pci', description: 'Built-in Audio', volume: 65, muted: false, is_default: true  },
        { index: 1, name: 'bluez_sink.AA',   description: 'WH-1000XM5',     volume: 80, muted: false, is_default: false },
      ]},
      'audio:sources': { status: 'success', data: [
        { index: 0, name: 'alsa_input.pci', description: 'Built-in Microphone', volume: 75, muted: false, is_default: true },
      ]},
      'display:list': { status: 'success', data: [
        { name: 'eDP-1', connected: true, primary: true, current_mode: '1920x1080', rotation: 'normal', position: [0,0],
          modes: [
            { resolution: '1920x1080', refresh_rates: [144, 120, 60], current: true,  preferred: true  },
            { resolution: '1280x720',  refresh_rates: [60],            current: false, preferred: false },
          ]},
      ]},
      'power:status': { status: 'success', data: { has_battery: true, battery_percent: 72, battery_state: 'Discharging', on_battery: true, time_remaining: '3h 22min', power_profile: 'balanced' } },
      'theme:get':    { status: 'success', data: { gtk_theme: 'Pop-dark', color_scheme: 'dark', is_dark: true, accent_color: 'blue', icon_theme: 'Pop', font_name: 'Fira Sans 11', cursor_theme: 'Pop' } },
      'theme:list':   { status: 'success', data: ['Adwaita', 'Adwaita-dark', 'Pop', 'Pop-dark', 'Yaru', 'Yaru-dark'] },
      'caps:list':    { status: 'success', data: [
        { name: 'CAP_NET_ADMIN', bit: 12, description: 'Perform network-related operations' },
        { name: 'CAP_NET_RAW',   bit: 13, description: 'Use RAW and PACKET sockets'         },
        { name: 'CAP_SYS_ADMIN', bit: 21, description: 'Perform system administration'      },
      ]},
    };
    return Promise.resolve(mocks[route] || { status: 'success', data: null });
  }
}

export const vertebrClient = new VertebrClient();
