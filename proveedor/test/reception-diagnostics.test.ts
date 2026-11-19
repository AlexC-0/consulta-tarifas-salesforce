import assert from 'node:assert/strict';
import { test } from 'node:test';
import { randomBytes, randomUUID } from 'node:crypto';
import { buildFaultHarness, type Scenario } from '../scripts/fault-harness.ts';
import { summarizeReceptions, type ReceptionEvent } from '../scripts/reception-diagnostics.ts';
import { postOnce } from '../scripts/single-http.ts';

test('200/401/429/503: una entrada, un hook y una respuesta no son tres peticiones', async () => {
  const apiKey = randomBytes(32).toString('hex');
  const events: ReceptionEvent[] = [];
  let scenario: Scenario = 'valid';
  const app = buildFaultHarness({ apiKey, log: () => {}, scenario: () => scenario, diagnostic: event => events.push(event) });
  const address = await app.listen({ host: '127.0.0.1', port: 0 });
  try {
    for (const [mode, status] of [['valid',200],['unauthorized',401],['rate-limit',429],['unavailable',503]] as const) {
      scenario = mode;
      const requestId = randomUUID();
      const result = await postOnce(new URL('/v1/tarifas/consultar', address), apiKey, requestId);
      assert.equal(result.status, status); assert.equal(result.operations, 1); assert.equal(result.socketAssignments, 1);
      const summary = summarizeReceptions(events, requestId);
      assert.equal(summary.httpEntries, 1); assert.equal(summary.faultHooks, 1); assert.equal(summary.responses, 1);
      assert.equal(summary.receptions[0].events.at(-1)?.status, status);
      assert.deepEqual(summary.receptions[0].events.map(event => event.event), ['http-entry','fault-hook','http-response']);
    }
    // Dos entradas reales que comparten correlación deben conservar identidades distintas.
    const repeated = randomUUID();
    await postOnce(new URL('/v1/tarifas/consultar', address), apiKey, repeated);
    await postOnce(new URL('/v1/tarifas/consultar', address), apiKey, repeated);
    assert.equal(summarizeReceptions(events, repeated).httpEntries, 2);
    assert.throws(() => summarizeReceptions([...events, events[0]], repeated), /Registro duplicado/);
    assert.equal(new Set(events.map(event => event.sequence)).size, events.length);
    assert.equal(new Set(events.map(event => event.runId)).size, 1);
    assert(!JSON.stringify(events).includes(apiKey));
  } finally { await app.close(); }
});

test('una clave incorrecta tiene entrada y respuesta, sin ejecución del fallo inducido', async () => {
  const events: ReceptionEvent[] = [];
  const app = buildFaultHarness({ apiKey: randomBytes(32).toString('hex'), log: () => {},
    scenario: () => 'rate-limit', diagnostic: event => events.push(event) });
  const address = await app.listen({ host: '127.0.0.1', port: 0 });
  try {
    const id = randomUUID();
    assert.equal((await postOnce(new URL('/v1/tarifas/consultar', address), 'incorrecta', id)).status, 401);
    const summary = summarizeReceptions(events, id);
    assert.equal(summary.httpEntries, 1); assert.equal(summary.faultHooks, 0); assert.equal(summary.responses, 1);
  } finally { await app.close(); }
});
