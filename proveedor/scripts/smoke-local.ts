// HTTP loopback con secreto efímero; no cambia la clave de P05.
import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
import { buildApp } from '../src/app.ts';

const apiKey = randomBytes(32).toString('hex');
const app = buildApp({ apiKey });
try {
  const address = await app.listen({ host: '127.0.0.1', port: 3055 });
  const health = await fetch(address + '/health');
  assert.equal(health.status, 200);
  assert.deepEqual(await health.json(), { status: 'ok' });
  const records = [];
  for (const [productCode, quantity, expectedTotal] of [
    ['PROD-001', 3, '59.70'], ['PROD-002', 2, '251.00'], ['PROD-003', 7, '6.93'], ['PROD-999', 1, null],
  ] as const) {
    const requestId = randomUUID();
    const response = await fetch(address + '/v1/tarifas/consultar', {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'X-API-Key': apiKey, 'X-Request-Id': requestId },
      body: JSON.stringify({ productCode, quantity }),
    });
    const quote = await response.json() as Record<string, unknown>;
    assert.equal(quote.requestId, requestId);
    assert.equal(response.status, expectedTotal === null ? 404 : 200);
    if (expectedTotal === null) {
      assert.equal((quote.error as { code: string }).code, 'PRODUCT_NOT_FOUND');
    } else {
      assert.equal(quote.productCode, productCode); assert.equal(quote.quantity, quantity);
      assert.equal(quote.currency, 'EUR'); assert.equal(quote.totalPrice, expectedTotal);
    }
    records.push({ productCode, quantity, requestId, status: response.status, totalPrice: quote.totalPrice });
  }
  for (const key of [undefined, 'incorrecta']) {
    const headers: Record<string, string> = { 'Content-Type': 'application/json', 'X-Request-Id': randomUUID() };
    if (key) headers['X-API-Key'] = key;
    const denied = await fetch(address + '/v1/tarifas/consultar', { method: 'POST', headers,
      body: JSON.stringify({ productCode: 'PROD-001', quantity: 3 }) });
    assert.equal(denied.status, 401);
    assert.equal((await denied.json() as { error: { code: string } }).error.code, 'UNAUTHORIZED');
  }
  process.stdout.write(JSON.stringify({ result: 'PASS', transport: 'HTTP loopback', records, unauthorized: [401, 401] }) + '\n');
} finally {
  await app.close();
}
