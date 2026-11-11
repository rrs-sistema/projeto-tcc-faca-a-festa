// Registra antes do SDK para manter o destino do clique na notificação.
self.addEventListener('notificationclick', event => {
    const data = event.notification.data?.FCM_MSG?.data;
    if (data?.screen !== 'chat_cotacao' && data?.screen !== 'autorizacao_repasse') return;
    event.stopImmediatePropagation();
    event.notification.close();
    const url = new URL(self.registration.scope);
    url.pathname = '/';
    url.search = new URLSearchParams({
        push_screen: data.screen,
        push_destinatario: data.id_destinatario,
        ...(data.screen === 'chat_cotacao'
            ? { push_cotacao: data.id_cotacao, push_fornecedor: data.id_fornecedor }
            : { push_orcamento: data.id_orcamento }),
    }).toString();
    event.waitUntil((async () => {
        const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
        const existing = windows.find(client => new URL(client.url).origin === url.origin);
        if (existing) {
            const navigated = await existing.navigate(url.href);
            if (navigated) await navigated.focus();
        } else {
            await self.clients.openWindow(url.href);
        }
    })());
});

importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyDl3iHPrTS4ELhh6wlhWqnS255sjMjijOo",
    authDomain: "faca-a-festa.firebaseapp.com",
    projectId: "faca-a-festa",
    messagingSenderId: "300274184803",
    appId: "1:300274184803:web:5c83fc48b8976ff035fe56"
});

const messaging = firebase.messaging();
