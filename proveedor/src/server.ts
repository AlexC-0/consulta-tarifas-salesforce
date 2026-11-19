import { buildApp } from './app.ts';

try {
  const app = buildApp({ apiKey: process.env.P05_API_KEY ?? '' });
  await app.listen({ host: '127.0.0.1', port: 3055 });
  for (const signal of ['SIGINT', 'SIGTERM'] as const) {
    process.once(signal, () => { void app.close(); });
  }
} catch {
  process.stderr.write('No se pudo iniciar P05: comprueba el secreto local y la disponibilidad de 127.0.0.1:3055.\n');
  process.exitCode = 1;
}
