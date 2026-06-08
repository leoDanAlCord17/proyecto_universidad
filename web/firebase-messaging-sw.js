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
