// VERTEBR — models/wifi/Network.js
// Modèle domaine Wi-Fi avec propriétés calculées
// Auteur : Houssam | Licence : MIT

export class Network {
  constructor({ name, bssid = '', connected = false, signal = 0,
                secured = false, security = '--', frequency = '', in_use = false }) {
    this.name      = name;
    this.bssid     = bssid;
    this.connected = connected || in_use;
    this.signal    = signal;
    this.secured   = secured;
    this.security  = security;
    this.frequency = frequency;
    this.in_use    = in_use || connected;
  }

  /** Niveau de signal : 0-4 barres */
  get signalBars() {
    if (this.signal >= 75) return 4;
    if (this.signal >= 50) return 3;
    if (this.signal >= 25) return 2;
    if (this.signal >= 5)  return 1;
    return 0;
  }

  /** Classe CSS pour les barres de signal */
  get signalClass() {
    return `s${this.signalBars}`;
  }

  /** Label qualité du signal */
  get signalLabel() {
    const labels = ['Aucun', 'Faible', 'Moyen', 'Bon', 'Excellent'];
    return labels[this.signalBars];
  }

  /** Est en 5 GHz ? */
  get is5GHz() {
    return this.frequency.includes('5');
  }

  /** Résumé court pour l'affichage */
  get summary() {
    return `${this.frequency}${this.secured ? ' · ' + this.security : ' · Ouvert'}`;
  }
}
