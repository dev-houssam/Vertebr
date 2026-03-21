// VERTEBR — models/bluetooth/Device.js
// Auteur : Houssam | Licence : MIT

export class BluetoothDevice {
  constructor({ address, name, paired = false, connected = false,
                trusted = false, device_type = 'device' }) {
    this.address     = address;
    this.name        = name;
    this.paired      = paired;
    this.connected   = connected;
    this.trusted     = trusted;
    this.deviceType  = device_type;
  }

  /** Emoji selon le type de périphérique */
  get typeEmoji() {
    const map = {
      headphones: '🎧', keyboard: '⌨️',
      mouse: '🖱️',      phone: '📱',
      speaker: '🔊',    device: '📡',
    };
    return map[this.deviceType] || map.device;
  }

  /** Couleur accent selon le type */
  get accentColor() {
    const map = {
      headphones: '#4da3ff', keyboard: '#3dd68c',
      mouse: '#f5a623',      phone: '#7f5cff',
      speaker: '#ff5c5c',    device: '#8a8fa8',
    };
    return map[this.deviceType] || map.device;
  }

  /** Résumé de statut */
  get statusLabel() {
    if (this.connected) return 'Connecté';
    if (this.paired)    return 'Couplé';
    return 'Disponible';
  }
}
