// Arranque explícito; no se utiliza desde npm start. Sin endpoints de control.
import { buildFaultHarness, readScenario } from './fault-harness.ts';

if (process.argv[2] !== '--enable-fault-tests' || !process.argv[3]) {
  throw new Error('Requiere --enable-fault-tests y ruta local del escenario.');
}
const path = process.argv[3];
const trace = process.argv[4] === '--trace-receptions';
if (process.argv.length > 5 || (process.argv[4] && !trace)) throw new Error('Opción de diagnóstico inválida.');
readScenario(path);
const app = buildFaultHarness({ apiKey: process.env.P05_API_KEY ?? '', scenario: () => readScenario(path),
  ...(trace ? { log: () => {}, diagnostic: event => { process.stdout.write(JSON.stringify(event)+'\n'); } }
    : { observed: (requestId, scenario) => { process.stdout.write(JSON.stringify({ requestId, scenario, event: 'fault-test' })+'\n'); } }) });
await app.listen({ host: '127.0.0.1', port: 3055 });
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.once(signal, () => { void app.close(); });
}
