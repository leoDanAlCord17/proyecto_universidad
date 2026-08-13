// IMPORTANTE: notificationclick debe registrarse ANTES de cargar/inicializar
// el SDK de Firebase Messaging más abajo. Es un comportamiento documentado
// del SDK: si firebase.messaging() se llama primero, Firebase registra su
// propio manejador de notificationclick y el nuestro deja de dispararse (o
// queda inconsistente) — es justo lo que nos estaba pasando: la notificación
// se cerraba sola sin abrir/enfocar la app.
//
// Este Service Worker se registra en un scope propio y aislado
// ('/firebase-cloud-messaging-push-scope', ver web/index.html) para no
// competir con flutter_service_worker.js por el control de la página raíz.
// Consecuencia: ningún cliente (pestaña) real de la app cae jamás DENTRO de
// este scope, así que clients.matchAll() llamado desde acá siempre devuelve
// una lista vacía — no hay forma de "encontrar y enfocar" una pestaña ya
// abierta desde este Service Worker. openWindow() sí funciona igual (abre
// cualquier URL del mismo origen sin importar el scope del que se llame).
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyD7NInOIx0MmiWCkxHw1wrAICvm_zf_kT4",
  authDomain: "activity-14938.firebaseapp.com",
  projectId: "activity-14938",
  storageBucket: "activity-14938.firebasestorage.app",
  messagingSenderId: "734695397025",
  appId: "1:734695397025:web:b31fc635597404703ac2e0",
});

const messaging = firebase.messaging();

// FCM muestra automáticamente las notificaciones con campo 'notification'.
// onBackgroundMessage solo se necesita para mensajes data-only.

// index.html tiene su propia lógica de auto-activación (SKIP_WAITING), pero
// SOLO aplica al Service Worker de scope raíz (flutter_service_worker.js) —
// nunca actuaba sobre este archivo. Sin skipWaiting()/clients.claim() acá,
// un usuario con una versión vieja de este Service Worker se quedaba con
// ella indefinidamente: el navegador instala la versión nueva pero no la
// activa hasta que cierre TODAS las pestañas de la PWA, cosa que en una app
// instalada casi nunca pasa.
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
