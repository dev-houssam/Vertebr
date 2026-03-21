// VERTEBR — electron/main.js
// Point d'entrée Electron
// Auteur : Houssam | Licence : MIT

const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const net  = require('net');
const fs   = require('fs');

const SOCKET_PATH = process.env.VERTEBR_SOCKET || '/tmp/vertebr.sock';

// Détection du mode :
// - VERTEBR_DEV=1 → mode développement (Vite sur localhost:5173)
// - Sinon         → charge le dist/ compilé directement
const isDev = process.env.VERTEBR_DEV === '1';

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width:            1200,
    height:           780,
    minWidth:         900,
    minHeight:        600,
    frame:            false,
    transparent:      false,
    backgroundColor:  '#0f1115',
    titleBarStyle:    'hidden',
    webPreferences: {
      preload:          path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration:  false,
    }
  });

  if (isDev) {
    // Mode dev : Vite doit tourner (npm run dev dans un autre terminal)
    console.log('[Vertebr] Mode DEV → http://localhost:5173');
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    // Mode production : charge le build statique
    // Cherche dist/ à côté du dossier frontend/
    const distPaths = [
      path.join(__dirname, '../frontend/dist/index.html'),  // depuis electron/
      path.join(__dirname, '../dist/index.html'),           // fallback
      path.join(process.cwd(), 'frontend/dist/index.html'),// depuis vertebr/
    ];

    const distFile = distPaths.find(p => fs.existsSync(p));

    if (distFile) {
      console.log('[Vertebr] Chargement du build statique :', distFile);
      mainWindow.loadFile(distFile);
    } else {
      // Dernier recours : afficher une page d'erreur informative
      console.error('[Vertebr] dist/ introuvable. Chemins testés :', distPaths);
      mainWindow.loadURL(`data:text/html,
        <html>
          <body style="background:#0f1115;color:#f0f1f5;font-family:sans-serif;padding:40px;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0">
            <div style="font-size:48px;margin-bottom:20px">🦴</div>
            <h2 style="color:#4da3ff;margin-bottom:12px">Vertebr — Build manquant</h2>
            <p style="color:#8a8fa8;margin-bottom:24px">Le frontend n'est pas compilé. Lance :</p>
            <pre style="background:rgba(255,255,255,0.05);padding:16px;border-radius:12px;border:1px solid rgba(255,255,255,0.1);color:#3dd68c;font-size:14px">cd frontend
npm install
npm run build</pre>
            <p style="color:#555a72;margin-top:20px;font-size:12px">Puis relance : npx electron@28 ../electron/main.js</p>
          </body>
        </html>
      `);
    }
  }

  // Afficher la DevTools avec F12
  mainWindow.webContents.on('before-input-event', (event, input) => {
    if (input.key === 'F12') {
      mainWindow.webContents.toggleDevTools();
    }
  });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// ── IPC : Communication avec le daemon Vertebr ──────────────

function callDaemon(route, payload = {}) {
  return new Promise((resolve, reject) => {
    const client = net.createConnection(SOCKET_PATH);
    const request = JSON.stringify({ route, payload }) + '\n';
    let responseData = '';

    const timeout = setTimeout(() => {
      client.destroy();
      reject(new Error(`Timeout (10s) sur la route ${route}`));
    }, 10000);

    client.on('connect', () => {
      client.write(request);
    });

    client.on('data', (data) => {
      responseData += data.toString();
      if (responseData.includes('\n')) {
        clearTimeout(timeout);
        client.end();
        try {
          resolve(JSON.parse(responseData.trim()));
        } catch (e) {
          reject(new Error(`Réponse JSON invalide : ${responseData}`));
        }
      }
    });

    client.on('error', (err) => {
      clearTimeout(timeout);
      reject(new Error(`Daemon injoignable : ${err.message}`));
    });

    client.on('close', () => {
      clearTimeout(timeout);
    });
  });
}

ipcMain.handle('vertebr:call', async (event, route, payload) => {
  try {
    return await callDaemon(route, payload);
  } catch (err) {
    console.error(`[Vertebr IPC] ${route} →`, err.message);
    return { status: 'error', error: err.message, code: 'ECONNECT' };
  }
});

// Contrôles de fenêtre custom (titlebar frameless)
ipcMain.on('window:minimize', () => mainWindow?.minimize());
ipcMain.on('window:maximize', () => {
  if (mainWindow?.isMaximized()) mainWindow.unmaximize();
  else mainWindow?.maximize();
});
ipcMain.on('window:close', () => mainWindow?.close());
