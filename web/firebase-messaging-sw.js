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

// Muestra la notificación cuando la app está en segundo plano o cerrada
messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  });
});
