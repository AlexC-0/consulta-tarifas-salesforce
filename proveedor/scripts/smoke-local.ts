// Prueba HTTP real de loopback con secreto efímero; no configura el secreto de Alex.
import assert from 'node:assert/strict';
import { randomBytes, randomUUID } from 'node:crypto';
import { buildApp } from '../src/app.ts';

const apiKey = randomBytes(32).toString('hex');
const app = buildApp({ apiKey });
try {
  const address = await app.listen({ host: '127.0.0.1', port: 3055 });
  const health = await fetch(address + '/health');
  assert.deepEqual(await health.json(), { status: 'ok' });
  const requestId = randomUUID();
  const response = await fetch(address + '/v1/tarifas/consultar', {
    method: 'POST', headers: { 'Content-Type': 'application/json', 'X-API-Key': apiKey, 'X-Request-Id': requestId },
    body: JSON.stringify({ productCode: 'PROD-001', quantity: 3 }),
  });
  assert.equal(response.status, 200);
  const quote = await response.json() as Record<string, unknown>;
  assert.equal(quote.requestId, requestId);
  assert.equal(quote.productCode, 'PROD-001');
  assert.equal(quote.quantity, 3);
  assert.equal(quote.currency, 'EUR');
  assert.equal(quote.unitPrice, '19.90');
  assert.equal(quote.totalPrice, '59.70');
  for (const key of [undefined, 'incorrecta']) {
    const headers: Record<string, string> = { 'Content-Type': 'application/json', 'X-Request-Id': randomUUID() };
    if (key) headers['X-API-Key'] = key;
    const rejected = await fetch(address + '/v1/tarifas/consultar', { method: 'POST', headers, body: JSON.stringify({ productCode: 'PROD-001', quantity: 3 }) });
    assert.equal(rejected.status, 401);
    assert.equal((await rejected.json() as { error: { code: string } }).error.code, 'UNAUTHORIZED');
  }
  process.stdout.write(JSON.stringify({ result: 'PASS', transport: 'HTTP loopback', requestId, unitPrice: quote.unitPrice, totalPrice: quote.totalPrice, unauthorized: [401, 401] }) + '\n');
} finally {
  await app.close();
}
