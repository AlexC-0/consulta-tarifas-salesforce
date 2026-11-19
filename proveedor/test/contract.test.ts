import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { randomBytes, randomUUID } from 'node:crypto';
import { Ajv2020 } from 'ajv/dist/2020.js';
import { buildApp } from '../src/app.ts';

// Los formatos también están acotados por los patrones del contrato.
// La duración y la coherencia de importes se verifican en app.test.ts.
const api = JSON.parse(readFileSync(new URL('../../docs/openapi.json', import.meta.url), 'utf8'));
const ajv = new Ajv2020({ strict: true, validateFormats: false });
const operation = api.paths['/v1/tarifas/consultar'].post;
const requestSchema = operation.requestBody.content['application/json'];
const validateRequest = ajv.compile(requestSchema.schema);
const validateQuote = ajv.compile(api.components.schemas.Tarifa);
const validateError = ajv.compile(api.components.schemas.Error);

test('ejemplos OpenAPI de los tres productos y producto desconocido', () => {
  for (const example of Object.values(requestSchema.examples) as { value: unknown }[]) {
    assert.ok(validateRequest(example.value), JSON.stringify(validateRequest.errors));
  }
  for (const example of Object.values(operation.responses['200'].content['application/json'].examples) as { value: unknown }[]) {
    assert.ok(validateQuote(example.value), JSON.stringify(validateQuote.errors));
  }
});
test('respuestas reales por inyección cumplen OpenAPI para catálogo, 404 y 401', async (t) => {
  const key = randomBytes(32).toString('hex');
  const app = buildApp({ apiKey: key, log: () => {} });
  t.after(() => app.close());
  for (const [productCode, quantity, status] of [
    ['PROD-001', 3, 200], ['PROD-002', 2, 200], ['PROD-003', 7, 200], ['PROD-999', 1, 404],
  ] as const) {
    const requestId = randomUUID();
    const response = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar',
      headers: { 'x-api-key': key, 'x-request-id': requestId }, payload: { productCode, quantity } });
    assert.equal(response.statusCode, status);
    const validate = status === 200 ? validateQuote : validateError;
    assert.ok(validate(response.json()), JSON.stringify(validate.errors));
    assert.equal(response.json().requestId, requestId);
  }
  const denied = await app.inject({ method: 'POST', url: '/v1/tarifas/consultar',
    headers: { 'x-request-id': randomUUID() }, payload: { productCode: 'PROD-001', quantity: 1 } });
  assert.equal(denied.statusCode, 401);
  assert.ok(validateError(denied.json()), JSON.stringify(validateError.errors));
});
test('contrato diferencia versión de esquema y tarifa, precisión y tipos', () => {
  const example = operation.responses['200'].content['application/json'].examples['PROD-001'].value;
  assert.ok(validateQuote({ ...example, tariffVersion: 'tarifa-nueva' }));
  assert.ok(validateQuote({ ...example, tariffVersion: 'v'.repeat(64) }));
  for (const patch of [
    { schemaVersion: '2' }, { tariffVersion: '' }, { tariffVersion: '   ' },
    { tariffVersion: 'v'.repeat(65) }, { tariffVersion: 1 },
    { unitPrice: '0.00' }, { unitPrice: '19.900' }, { unitPrice: 19.90 },
    { totalPrice: '59.7' }, { quantity: '3' }, { quantity: 1.5 },
  ]) {
    assert.equal(validateQuote({ ...example, ...patch }), false, JSON.stringify(patch));
  }
});
