import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { buildApp, UUID_PATTERN } from '../src/app.ts';
import type { AccessEntry } from '../src/app.ts';

const key = randomBytes(32).toString('hex');
const headers = () => ({ 'x-api-key': key, 'x-request-id': randomUUID() });
const body = { productCode: 'PROD-001', quantity: 3 };
async function fixture(t: { after: (fn: () => Promise<void>) => void }, log?: (e: AccessEntry) => void) {
  const app = buildApp({ apiKey: key, log: log ?? (() => {}) });
  t.after(() => app.close());
  return app;
}
test('consulta válida: correlación, importes, UUID y vigencia de 24 horas', async (t) => {
  const app = await fixture(t);
  const h = headers();
  const before = Date.now();
  const response = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar', headers: h, payload: body });
  const after = Date.now();
  assert.equal(response.statusCode, 200);
  const quote = response.json();
  assert.equal(quote.requestId, h['x-request-id']);
  assert.match(quote.quoteId, UUID_PATTERN);
  assert.equal(quote.productCode, 'PROD-001');
  assert.equal(quote.quantity, 3);
  assert.equal(quote.schemaVersion, '1');
  assert.equal(quote.tariffVersion, 'demo-1');
  assert.equal(quote.currency, 'EUR');
  assert.equal(quote.unitPrice, '19.90');
  assert.equal(quote.totalPrice, '59.70');
  assert.match(quote.issuedAt, /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
  assert.equal(Date.parse(quote.validUntil) - Date.parse(quote.issuedAt), 86_400_000);
  assert.ok(Date.parse(quote.issuedAt) >= before && Date.parse(quote.issuedAt) <= after);
});
for (const [quantity, total] of [[1, '19.90'], [10_000, '199000.00']] as const) {
  test('cantidad límite aceptada: ' + quantity, async (t) => {
    const app = await fixture(t);
    const response = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar', headers: headers(), payload: { ...body, quantity } });
    assert.equal(response.statusCode, 200);
    assert.equal(response.json().totalPrice, total);
  });
}
for (const quantity of [0, -1, 1.5, 10_001, '3', null, true]) {
  test('rechaza cantidad ' + JSON.stringify(quantity), async (t) => {
    const app = await fixture(t);
    const response = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar', headers: headers(), payload: { ...body, quantity } });
    assert.equal(response.statusCode, 400);
    assert.equal(response.json().error.code, 'INVALID_REQUEST');
  });
}
for (const payload of [{ productCode: 'PROD-001' }, { ...body, unitPrice: '0.01' }, { ...body, productCode: '' }, []]) {
  test('rechaza estructura inválida ' + JSON.stringify(payload), async (t) => {
    const app = await fixture(t);
    const response = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar', headers: headers(), payload });
    assert.equal(response.statusCode, 400);
  });
}
test('producto desconocido', async (t) => {
  const app = await fixture(t);
  const response = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar', headers: headers(), payload: { ...body, productCode: 'PROD-999' } });
  assert.equal(response.statusCode, 404);
  assert.equal(response.json().error.code, 'PRODUCT_NOT_FOUND');
});
for (const supplied of [undefined, 'incorrecta']) {
  test('rechaza clave ' + (supplied ? 'incorrecta' : 'ausente') + ' antes de interpretar el cuerpo', async (t) => {
    const app = await fixture(t);
    const h: Record<string, string> = { 'content-type': 'application/json' };
    if (supplied) h['x-api-key'] = supplied;
    const response = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar', headers: h, payload: '{malformed' });
    assert.equal(response.statusCode, 401);
    assert.equal(response.json().error.code, 'UNAUTHORIZED');
    assert.match(response.json().requestId, UUID_PATTERN);
  });
}
for (const requestId of [undefined, 'arbitrary-sensitive-input']) {
  test('UUID inválido o ausente genera correlación segura: ' + String(requestId), async (t) => {
    const entries: AccessEntry[] = [];
    const app = await fixture(t, (entry) => entries.push(entry));
    const h: Record<string, string> = { 'x-api-key': key };
    if (requestId) h['x-request-id'] = requestId;
    const response = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar', headers: h, payload: body });
    assert.equal(response.statusCode, 400);
    assert.match(response.json().requestId, UUID_PATTERN);
    assert.equal(entries[0].requestId, response.json().requestId);
    assert.deepEqual(Object.keys(entries[0]).sort(), ['durationMs', 'requestId', 'status']);
    assert.ok(!JSON.stringify(entries).includes(key));
    assert.ok(!JSON.stringify(entries).includes('arbitrary-sensitive-input'));
  });
}
for (const [contentType, payload] of [['application/json', '{broken'], ['text/plain', 'not json'], ['application/json', JSON.stringify({ padding: 'x'.repeat(5000) })]]) {
  test('error de cuerpo normalizado: ' + contentType + '/' + payload.length, async (t) => {
    const app = await fixture(t);
    const response = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar', headers: { ...headers(), 'content-type': contentType }, payload });
    assert.equal(response.statusCode, 400);
    assert.equal(response.json().error.code, 'INVALID_REQUEST');
  });
}
test('cada consulta produce un quoteId nuevo', async (t) => {
  const app = await fixture(t);
  const request = { method: 'POST' as const, url: '/v1/tarifas/consultar', headers: headers(), payload: body };
  const first = (await app.inject(request)).json();
  const second = (await app.inject(request)).json();
  assert.notEqual(first.quoteId, second.quoteId);
});
test('health mínimo sin autenticación', async (t) => {
  const app = await fixture(t);
  const response = await app.inject({ method: 'GET', url: '/health' });
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), { status: 'ok' });
});
test('error interno no expone detalles', async (t) => {
  const app = await fixture(t);
  app.get('/test-error', async () => { throw new Error('private-detail-' + key); });
  const response = await app.inject('/test-error');
  assert.equal(response.statusCode, 500);
  assert.equal(response.json().error.code, 'INTERNAL_ERROR');
  assert.ok(!response.body.includes('private-detail'));
  assert.ok(!response.body.includes(key));
});
test('sin secreto válido no se construye el servicio', () => {
  for (const apiKey of ['', 'placeholder']) {
    assert.throws(() => buildApp({ apiKey }), /P05_API_KEY/);
  }
});
test('el proceso falla al arrancar sin secreto', () => {
  const result = spawnSync(process.execPath, ['src/server.ts'], {
    cwd: new URL('../', import.meta.url), env: { ...process.env, P05_API_KEY: '' }, encoding: 'utf8',
  });
  assert.equal(result.status, 1);
  assert.equal(result.stdout, '');
  assert.match(result.stderr, /No se pudo iniciar P05/);
});
