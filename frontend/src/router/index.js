// VERTEBR — router/index.js
import { createRouter, createWebHashHistory } from 'vue-router';
import { menuRoutes } from './routes.js';

const router = createRouter({
  history: createWebHashHistory(),
  routes:  menuRoutes,
});

export default router;
