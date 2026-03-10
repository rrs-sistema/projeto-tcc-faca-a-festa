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
