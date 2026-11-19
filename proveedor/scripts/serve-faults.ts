// Arranque explícito; no se utiliza desde npm start. Sin endpoints de control.
import { buildFaultHarness, readScenario } from './fault-harness.ts';

if (process.argv[2] !== '--enable-fault-tests' || !process.argv[3]) {
  throw new Error('Requiere --enable-fault-tests y ruta local del escenario.');
}
const path = process.argv[3];
readScenario(path);
const app = buildFaultHarness({ apiKey: process.env.P05_API_KEY ?? '', scenario: () => readScenario(path),
  observed: (requestId, scenario) => process.stdout.write(JSON.stringify({ requestId, scenario, event: 'fault-test' })+'\n') });
await app.listen({ host: '127.0.0.1', port: 3055 });
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.once(signal, () => { void app.close(); });
}
