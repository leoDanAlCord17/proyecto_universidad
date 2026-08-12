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

// Sin esto, tocar la notificación del sistema (app en segundo plano o
// cerrada) no hacía nada: el navegador solo cierra la notificación por
// defecto, no hay ningún comportamiento de "abrir la app" incorporado.
// Si ya hay una pestaña/ventana de la app abierta, la enfoca; si no, abre
// una nueva en la raíz.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((lista) => {
      for (const cliente of lista) {
        if ('focus' in cliente) return cliente.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    })
  );
});
