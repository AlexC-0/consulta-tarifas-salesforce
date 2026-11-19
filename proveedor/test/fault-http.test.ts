import assert from 'node:assert/strict';
import { test } from 'node:test';
import { randomBytes, randomUUID } from 'node:crypto';
import { performance } from 'node:perf_hooks';
import { buildFaultHarness, type Scenario } from '../scripts/fault-harness.ts';

test('matriz HTTP loopback real, timeout de 10 s y recuperación sin reintentos', async () => {
  const apiKey = randomBytes(32).toString('hex');
  let scenario: Scenario = 'valid';
  const seen: string[] = [];
  const app = buildFaultHarness({ apiKey, scenario: () => scenario, log: () => {},
    observed: requestId => seen.push(requestId) });
  const address = await app.listen({ host: '127.0.0.1', port: 0 });
  const post = (requestId: string, key = apiKey, productCode = 'PROD-001', quantity = 3) => fetch(address+'/v1/tarifas/consultar', {
    method: 'POST', headers: { 'Content-Type':'application/json','X-API-Key':key,'X-Request-Id':requestId },
    body: JSON.stringify({ productCode, quantity }), signal: AbortSignal.timeout(10_000),
  });
  try {
    for (const [key, product, quantity, status] of [[apiKey,'PROD-001',0,400],
      ['incorrecta','PROD-001',3,401],[apiKey,'PROD-999',3,404]] as const) {
      const requestId = randomUUID(); const response = await post(requestId,key,product,quantity);
      assert.equal(response.status,status);
      assert.equal((await response.json() as {requestId:string}).requestId,requestId);
    }
    assert.equal(seen.length,0,'Los fallos inducidos no preceden a autenticación o validación.');
    for (const mode of ['valid','unauthorized','rate-limit','unavailable','inconsistent','expired','future'] as const) {
      scenario=mode;const requestId=randomUUID();const before: number=seen.length;
      const response=await post(requestId);const body=await response.json() as Record<string,unknown>;
      const statuses: Partial<Record<Scenario,number>> = {unauthorized:401,'rate-limit':429,unavailable:503};
      const expected = statuses[mode] ?? 200;
      assert.equal(response.status,expected);assert.equal(body.requestId,requestId);
      assert.equal(seen.length,before+1);assert.equal(seen.at(-1),requestId);
      if(mode==='valid') assert.equal(body.totalPrice,'59.70');
      if(mode==='inconsistent') assert.equal(body.totalPrice,'0.00');
      if(mode==='expired'||mode==='future') {
        const issued=Date.parse(body.issuedAt as string),expiry=Date.parse(body.validUntil as string);
        assert.equal(expiry-issued,86_400_000);
        assert(mode==='expired'?expiry<Date.now():issued>Date.now()+1000);
      }
    }
    scenario='timeout';let before=seen.length;const started=performance.now();
    await assert.rejects(post(randomUUID()),{name:'TimeoutError'});
    assert(performance.now()-started>=9500,'Timeout de red real de aproximadamente 10 s.');
    assert.equal(seen.length,before+1);
    scenario='disconnect';before=seen.length;
    await assert.rejects(post(randomUUID()));assert.equal(seen.length,before+1);
    scenario='valid';before=seen.length;
    const recovered=await post(randomUUID());assert.equal(recovered.status,200);
    assert.equal((await recovered.json() as {totalPrice:string}).totalPrice,'59.70');
    assert.equal(seen.length,before+1);
  } finally { await app.close(); }
  await assert.rejects(post(randomUUID()),'Conexión rechazada con el listener cerrado.');
});
