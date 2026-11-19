import http from 'node:http';
import https from 'node:https';
import { performance } from 'node:perf_hooks';

// Una única invocación de request, sin agente compartido, bucles ni seguimiento de redirecciones.
export async function postOnce(endpoint: URL, apiKey: string, requestId: string) {
  if (!['http:', 'https:'].includes(endpoint.protocol)) throw new Error('Protocolo no permitido.');
  const body = JSON.stringify({ productCode: 'PROD-001', quantity: 3 });
  const started = performance.now();
  let socketAssignments = 0;
  return await new Promise<{ requestId: string; operations: number; socketAssignments: number; status: number; elapsedMs: number }>((resolve, reject) => {
    const transport = endpoint.protocol === 'https:' ? https : http;
    const request = transport.request(endpoint, { method: 'POST', agent: false, headers: {
      'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body),
      'Accept': 'application/json', 'X-API-Key': apiKey, 'X-Request-Id': requestId,
    } }, response => {
      response.resume();
      response.once('error', () => reject(new Error('CLIENT_RESPONSE_ERROR')));
      response.once('end', () => {
        clearTimeout(deadline);
        resolve({ requestId, operations: 1, socketAssignments, status: response.statusCode ?? 0,
          elapsedMs: Math.round((performance.now() - started) * 100) / 100 });
      });
    });
    const deadline = setTimeout(() => request.destroy(new Error('CLIENT_TIMEOUT')), 10_000);
    request.on('socket', () => { socketAssignments++; });
    request.once('error', () => { clearTimeout(deadline); reject(new Error('CLIENT_TRANSPORT_ERROR')); });
    request.end(body);
  });
}
