// VERTEBR — configs/theme.config.js
// Configuration du système de thème HarmonyOS
// Auteur : Houssam | Licence : MIT

export const ThemeConfig = {
  /** Thème par défaut si le système ne peut pas être détecté */
  defaultMode: 'dark',

  /** Couleur d'accent par défaut */
  defaultAccent: '#4da3ff',

  /** Couleurs d'accent disponibles */
  accentColors: [
    { hex: '#4da3ff', name: 'Bleu Harmony',    gradient: 'linear-gradient(135deg,#4da3ff,#7f5cff)' },
    { hex: '#7f5cff', name: 'Violet',           gradient: 'linear-gradient(135deg,#7f5cff,#c084fc)' },
    { hex: '#3dd68c', name: 'Vert Emeraude',    gradient: 'linear-gradient(135deg,#3dd68c,#06b6d4)' },
    { hex: '#f5a623', name: 'Or Ambre',         gradient: 'linear-gradient(135deg,#f5a623,#ef4444)' },
    { hex: '#ff5c5c', name: 'Rouge Coral',      gradient: 'linear-gradient(135deg,#ff5c5c,#f97316)' },
    { hex: '#ec4899', name: 'Rose Fuchsia',     gradient: 'linear-gradient(135deg,#ec4899,#7f5cff)' },
    { hex: '#06b6d4', name: 'Cyan Arctique',    gradient: 'linear-gradient(135deg,#06b6d4,#3dd68c)' },
    { hex: '#f0f1f5', name: 'Blanc Lunaire',    gradient: 'linear-gradient(135deg,#f0f1f5,#c0c4d4)' },
  ],

  /** Intervalle de polling pour détecter les changements de thème système (ms) */
  systemThemePollInterval: 3000,
};
