// Receives push notifications while the SupaClean web app is in the
// background or closed. Chrome loads this file from the site root.
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// The web app's public Firebase settings (same as lib/firebase_options.dart).
firebase.initializeApp({
  apiKey: 'AIzaSyDuoKc22pBFIUBIu3l1V6yZi0a9T644otE',
  appId: '1:898732685504:web:ef6ba4cb2843b1c0415525',
  messagingSenderId: '898732685504',
  projectId: 'supaclean-e92e4',
  authDomain: 'supaclean-e92e4.firebaseapp.com',
  storageBucket: 'supaclean-e92e4.firebasestorage.app',
});

// Messages that carry a notification are shown by the browser itself.
firebase.messaging();
