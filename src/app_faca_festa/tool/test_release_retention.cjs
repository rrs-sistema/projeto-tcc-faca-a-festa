const { test } = require('node:test');
const assert = require('node:assert/strict');
const { platforms, objectName, validateCatalog, planRetention, readCatalog, applyPlan, hostingRetention } = require('./release_retention.cjs');
const now = Date.parse('2026-11-18T12:00:00Z');
const day = 86400000;
const bucketName = 'faca-a-festa.firebasestorage.app';
function catalog(spec, build = 10) {
  return { identity: spec.identity, published: true, build, sha256: 'a'.repeat(64), size: 53,
    url: `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(objectName(spec, build))}?alt=media&token=test` };
}
function file(spec, build, ageDays = 30) {
  return { name: objectName(spec, build), metadata: { timeCreated: new Date(now - ageDays * day).toISOString(),
    generation: String(100 + build), size: '53', metadata: { identity: spec.identity, sha256: 'a'.repeat(64) } } };
}
for (const spec of platforms) {
  test(`${spec.name}: preserves current, two previous builds, recent and future uploads`, () => {
    const files = [1, 2, 3, 8, 9, 10, 11].map(build => file(spec, build));
    files.push(file(spec, 4, 6));
    const plan = planRetention(files, spec, catalog(spec), now);
    assert.deepEqual(plan.remove.map(item => item.build), [1, 2, 3]);
    assert.equal(plan.bytesToRemove, 159);
    assert.equal(plan.retained.length, 5);
  });
  test(`${spec.name}: refuses cleanup if current artifact is missing or differs`, () => {
    assert.throws(() => planRetention([], spec, catalog(spec), now));
    const wrong = file(spec, 10);
    wrong.metadata.metadata.sha256 = 'b'.repeat(64);
    assert.throws(() => planRetention([wrong], spec, catalog(spec), now));
  });
  test(`${spec.name}: ignores user data, unknown files and malformed metadata`, () => {
    const files = [file(spec, 10), file(spec, 9), file(spec, 8)];
    const other = file(spec, 1);
    other.metadata.metadata.identity = 'another-app';
    const incomplete = file(spec, 2);
    incomplete.metadata.timeCreated = 'invalid';
    files.push(other, incomplete, { ...file(spec, 3), name: 'users/photo.jpg' },
      { ...file(spec, 4), name: `${spec.prefix}build-4/backup.zip` });
    assert.deepEqual(planRetention(files, spec, catalog(spec), now).remove, []);
  });
  test(`${spec.name}: current catalog must reference this bucket and artifact`, () => {
    validateCatalog(catalog(spec), spec, bucketName);
    assert.throws(() => validateCatalog({ ...catalog(spec), published: false }, spec, bucketName));
    assert.throws(() => validateCatalog({ ...catalog(spec), url: 'https://other.example/file' }, spec, bucketName));
    assert.throws(() => validateCatalog(catalog(spec), spec, 'another-bucket'));
  });
}
test('appcast divergence aborts cleanup before any deletion', async () => {
  const spec = platforms[0];
  const request = async url => url.endsWith('.json')
    ? new Response(JSON.stringify(catalog(spec)), { headers: { 'Content-Type': 'application/json' } })
    : new Response('<enclosure url="https://other.example/file" sparkle:version="9" />');
  await assert.rejects(readCatalog(spec, bucketName, request));
});
test('delete uses the recorded generation and stops when the catalog changes', async () => {
  const spec = platforms[0], current = catalog(spec);
  const plan = planRetention([1, 2, 8, 9, 10].map(build => file(spec, build)), spec, current, now);
  const deleted = [];
  const bucket = { name: bucketName, file: name => ({ delete: async options => deleted.push({ name, options }) }) };
  let calls = 0;
  await assert.rejects(applyPlan(bucket, plan, spec, current,
    async () => ++calls === 1 ? current : { ...current, build: 11 }));
  assert.deepEqual(deleted, [{ name: objectName(spec, 1), options: { ifGenerationMatch: '101' } }]);
});
test('Hosting excludes offline packages from publication', () => {
  const config = require('../firebase.json');
  assert.ok(config.hosting.ignore.includes('desktop/packages/**'));
  assert.ok(config.hosting.ignore.includes('android/packages/**'));
});
test('Hosting simulation never writes; application limits previous releases to two', async () => {
  const requests = [];
  const client = { request: async options => {
    requests.push(options);
    return { data: { name: 'sites/faca-a-festa/channels/live', retainedReleaseCount: 2147483647 } };
  } };
  const plan = await hostingRetention(client);
  assert.equal(plan.totalReleasesAfter, 3);
  assert.equal(requests.length, 1);
  await hostingRetention(client, true);
  assert.equal(requests[2].method, 'PATCH');
  assert.deepEqual(requests[2].params, { updateMask: 'retainedReleaseCount' });
  assert.deepEqual(requests[2].data, { retainedReleaseCount: 2 });
});
test('Hosting never increases an existing stricter retention policy', async () => {
  const requests = [];
  const client = { request: async options => {
    requests.push(options);
    return { data: { name: 'sites/faca-a-festa/channels/live', retainedReleaseCount: 1 } };
  } };
  await hostingRetention(client, true);
  assert.equal(requests.length, 1);
});
