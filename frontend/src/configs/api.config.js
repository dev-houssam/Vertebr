// VERTEBR — configs/api.config.js
// Configuration de la communication avec le daemon
// Auteur : Houssam | Licence : MIT

export const ApiConfig = {
  /** Chemin du socket UNIX (surcharger via VERTEBR_SOCKET env var) */
  socketPath:   '/tmp/vertebr.sock',

  /** Timeout en millisecondes pour les appels au daemon */
  timeout:      10_000,

  /** Nombre de tentatives en cas d'échec */
  retries:      2,

  /** Délai entre les tentatives (ms) */
  retryDelay:   500,
};
