// Instrumentación opcional del banco de pruebas; no se importa en el servidor normal.
import { randomUUID } from 'node:crypto';
import { performance } from 'node:perf_hooks';
import type { FastifyInstance, FastifyRequest } from 'fastify';
import type { IncomingMessage } from 'node:http';

export type ReceptionEvent = {
  runId: string; sequence: number; receptionId: string; requestId: string;
  scenario: string; event: 'http-entry' | 'fault-hook' | 'http-response' | 'http-aborted';
  at: string; elapsedMs: number; status?: number;
};
export function instrumentReceptions(app: FastifyInstance, scenario: () => string,
  emit: (event: ReceptionEvent) => void) {
  const runId = randomUUID();
  let sequence = 0;
  const arrivals = new WeakMap<IncomingMessage, { receptionId: string; scenario: string; started: number }>();
  const record = (request: FastifyRequest, event: ReceptionEvent['event'], status?: number) => {
    const arrival = arrivals.get(request.raw);
    if (!arrival) throw new Error('Falta una entrada HTTP para el evento de diagnóstico.');
    emit({ runId, sequence: ++sequence, receptionId: arrival.receptionId, requestId: request.id,
      scenario: arrival.scenario, event, at: new Date().toISOString(),
      elapsedMs: Math.round((performance.now() - arrival.started) * 100) / 100,
      ...(status === undefined ? {} : { status }) });
  };
  app.addHook('onRequest', async (request, reply) => {
    if (request.url !== '/v1/tarifas/consultar') return;
    if (arrivals.has(request.raw)) throw new Error('Entrada HTTP ya instrumentada.');
    arrivals.set(request.raw, { receptionId: randomUUID(), scenario: scenario(), started: performance.now() });
    record(request, 'http-entry');
    reply.raw.once('close', () => {
      if (!reply.raw.writableFinished) record(request, 'http-aborted');
    });
  });
  app.addHook('onResponse', async (request, reply) => {
    if (arrivals.has(request.raw)) record(request, 'http-response', reply.statusCode);
  });
  return (request: FastifyRequest) => record(request, 'fault-hook');
}

export function summarizeReceptions(events: ReceptionEvent[], requestId: string) {
  const sequenceKeys = new Set<string>();
  for (const event of events) {
    const key = `${event.runId}:${event.sequence}`;
    if (sequenceKeys.has(key)) throw new Error('Registro duplicado: no se puede contar la misma lectura dos veces.');
    sequenceKeys.add(key);
  }
  const selected = events.filter(event => event.requestId === requestId);
  const entries = selected.filter(event => event.event === 'http-entry');
  const ids = new Set(entries.map(event => `${event.runId}:${event.receptionId}`));
  if (ids.size !== entries.length) throw new Error('Identificador de recepción repetido en entradas.');
  if (selected.some(event => !ids.has(`${event.runId}:${event.receptionId}`))) throw new Error('Evento sin entrada HTTP.');
  return { httpEntries: ids.size, faultHooks: selected.filter(event => event.event === 'fault-hook').length,
    responses: selected.filter(event => event.event === 'http-response').length,
    receptions: entries.map(entry => ({ receptionId: entry.receptionId, runId: entry.runId,
      events: selected.filter(event => event.runId === entry.runId && event.receptionId === entry.receptionId) })) };
}
