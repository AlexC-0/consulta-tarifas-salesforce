// Exclusivo de pruebas. El servidor normal nunca importa este módulo.
import { readFileSync } from 'node:fs';
import { buildApp, type AccessEntry } from '../src/app.ts';
import { instrumentReceptions, type ReceptionEvent } from './reception-diagnostics.ts';

export const scenarios = ['valid', 'unauthorized', 'rate-limit', 'unavailable', 'inconsistent',
  'expired', 'future', 'timeout', 'disconnect'] as const;
export type Scenario = typeof scenarios[number];
export function readScenario(path: string): Scenario {
  const value = readFileSync(path, 'utf8').trim();
  if (!scenarios.includes(value as Scenario)) throw new Error('Escenario de prueba inválido.');
  return value as Scenario;
}
export function buildFaultHarness(options: {
  apiKey: string; scenario: () => Scenario; log?: (entry: AccessEntry) => void;
  observed?: (requestId: string, scenario: Scenario) => void;
  diagnostic?: (event: ReceptionEvent) => void;
}) {
  const app = buildApp({ apiKey: options.apiKey, log: options.log });
  const recordFault = options.diagnostic ? instrumentReceptions(app, options.scenario, options.diagnostic) : undefined;
  // Solo el proceso de pruebas: permite observar el timeout Apex de 10 s.
  app.server.setTimeout(20_000);
  app.addHook('onSend', async (request, reply, payload) => {
    if (request.url !== '/v1/tarifas/consultar' || reply.statusCode !== 200) return payload;
    // Solo se induce un fallo después de autenticación y validación normales.
    const scenario = options.scenario();
    options.observed?.(request.id, scenario);
    recordFault?.(request);
    const statuses: Partial<Record<Scenario, number>> = { unauthorized: 401, 'rate-limit': 429, unavailable: 503 };
    const status = statuses[scenario];
    if (status) {
      reply.code(status);
      return JSON.stringify({ requestId: request.id, error: { code: 'TEST_REJECTION', message: 'Rechazo controlado de prueba.' } });
    }
    if (scenario === 'timeout') await new Promise(resolve => setTimeout(resolve, 12_000));
    if (scenario === 'disconnect') { request.raw.socket.destroy(); return payload; }
    if (typeof payload !== 'string') throw new Error('Formato de prueba inesperado.');
    const body = JSON.parse(payload) as Record<string, unknown>;
    if (scenario === 'inconsistent') body.totalPrice = '0.00';
    if (scenario === 'expired' || scenario === 'future') {
      const issued = Date.now() + (scenario === 'expired' ? -86_405_000 : 60_000);
      body.issuedAt = new Date(issued).toISOString();
      body.validUntil = new Date(issued + 86_400_000).toISOString();
    }
    return JSON.stringify(body);
  });
  return app;
}
