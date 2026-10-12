// Keep this Firebase JS SDK version aligned with firebase_core_web in pubspec.lock.
importScripts(
  'https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js',
  'https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js',
);

const firebaseReady = fetch('/assets/.vscode/firebase.local.json')
  .then((response) => {
    if (!response.ok) throw new Error('Local Firebase config is unavailable');
    return response.json();
  })
  .then((configuration) => {
    const options = configuration.platforms && configuration.platforms.web;
    if (!options || !options.apiKey || !options.appId || !options.projectId) {
      throw new Error('Firebase web config is incomplete');
    }

    firebase.initializeApp(options);
    const messaging = firebase.messaging();
    messaging.onBackgroundMessage((payload) => {
      const title = payload.notification && payload.notification.title
        ? payload.notification.title
        : 'Movie Watchlist';
      const body = payload.notification && payload.notification.body
        ? payload.notification.body
        : '';
      return self.registration.showNotification(title, {
        body,
        icon: 'icons/Icon-192.png',
        data: payload.data || {},
      });
    });
  })
  .catch((error) => {
    console.info('Firebase messaging worker is inactive:', error.message);
  });

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = event.notification.data && event.notification.data.link;
  event.waitUntil(self.clients.openWindow(target || '/'));
});
