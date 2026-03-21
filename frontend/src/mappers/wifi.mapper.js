// VERTEBR — mappers/wifi.mapper.js
// Transformation DTO (API) ↔ Model (domaine)
// Auteur : Houssam | Licence : MIT
import { Network } from '@/models/wifi/Network.js';

export const wifiMapper = {
  /** DTO brut de l'API → instance Network avec méthodes */
  toModel(dto) {
    if (!dto) return null;
    return new Network(dto);
  },

  /** Liste de DTOs → liste de Network */
  toModelList(dtos) {
    return (dtos ?? []).map(dto => this.toModel(dto));
  },

  /** Network → payload pour l'API */
  toConnectPayload(network, password = null) {
    const payload = { ssid: network.name };
    if (password) payload.password = password;
    return payload;
  },
};
