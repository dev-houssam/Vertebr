// VERTEBR — electron/preload.js
// Bridge sécurisé entre renderer et main process
// Auteur : Houssam | Licence : MIT

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('vertebr', {
  /**
   * Appelle une route du daemon Vertebr
   * @param {string} route   - "module:action"
   * @param {object} payload - Données de la requête
   * @returns {Promise<{status: string, data?: any, error?: string}>}
   */
  call: (route, payload = {}) =>
    ipcRenderer.invoke('vertebr:call', route, payload),
});

contextBridge.exposeInMainWorld('windowControls', {
  minimize: () => ipcRenderer.send('window:minimize'),
  maximize: () => ipcRenderer.send('window:maximize'),
  close:    () => ipcRenderer.send('window:close'),
});
