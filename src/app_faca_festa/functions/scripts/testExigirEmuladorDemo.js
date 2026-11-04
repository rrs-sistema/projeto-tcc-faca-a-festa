const assert=require('node:assert/strict');
const {exigirEmuladorDemo:check}=require('./exigirEmuladorDemo');
const base=()=>({FIRESTORE_EMULATOR_HOST:'127.0.0.1:8080',GCLOUD_PROJECT:'demo-seguranca'});
assert.equal(check('demo-seguranca',base()),'demo-seguranca');
for(const extra of [{FIRESTORE_EMULATOR_HOST:''},{FIRESTORE_EMULATOR_HOST:'firestore.googleapis.com:443'},{GCLOUD_PROJECT:'faca-a-festa-prod'},{GOOGLE_CLOUD_PROJECT:'prod'},{GCLOUD_PROJECT:'demo-outro'},{FIREBASE_CONFIG:'arquivo.json'},{FIREBASE_CONFIG:JSON.stringify({projectId:'prod'})},{FIREBASE_AUTH_EMULATOR_HOST:'identitytoolkit.googleapis.com:443'},{STORAGE_EMULATOR_HOST:'https://storage.googleapis.com'},{FIREBASE_CONFIG:JSON.stringify({projectId:'demo-seguranca',databaseURL:'https://prod.firebaseio.com'})}])assert.throws(()=>check('demo-seguranca',{...base(),...extra}));
console.log('PASS barreira: loopback/demo e 10 configurações perigosas recusadas antes do SDK.');

const placeholder={...base(),FIREBASE_CONFIG:JSON.stringify({projectId:'demo-seguranca',databaseURL:'https://demo-seguranca-default-rtdb.firebaseio.com',storageBucket:'demo-seguranca.appspot.com'})};
check('demo-seguranca',placeholder);assert.deepEqual(JSON.parse(placeholder.FIREBASE_CONFIG),{projectId:'demo-seguranca'});
assert.throws(()=>check('demo-seguranca',{...base(),FIREBASE_CONFIG:JSON.stringify({projectId:'demo-seguranca',storageBucket:'prod.appspot.com'})}));
require('./exigirEmuladorDemo').bloquearRedeExterna();
assert.throws(()=>require('node:https').request('https://fcm.googleapis.com/v1/projects/prod/messages:send'));
assert.throws(()=>require('node:http2').connect('https://firestore.googleapis.com'));
(async()=>{await assert.rejects(()=>fetch('https://example.com'));console.log('PASS outbound HTTP/HTTP2/fetch refused without sending requests.');})().catch(e=>{console.error(e);process.exitCode=1;});
