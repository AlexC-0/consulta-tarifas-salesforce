import Fastify from 'fastify';
import { createHash, randomUUID, timingSafeEqual } from 'node:crypto';

export const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export type AccessEntry = { requestId: string; status: number; durationMs: number };
type Options = { apiKey: string; log?: (entry: AccessEntry) => void };
type QuoteRequest = { productCode: string; quantity: number };
// Catálogo ficticio versionado. Única fuente de precios de ejecución, en céntimos.
const catalogue = new Map([['PROD-001', 1990], ['PROD-002', 12550], ['PROD-003', 99]]);
const digest = (value: string) => createHash('sha256').update(value).digest();
const money = (cents: number) => Math.trunc(cents / 100) + '.' + String(cents % 100).padStart(2, '0');
const failure = (requestId: string, code: string, message: string) => ({ requestId, error: { code, message } });

export function buildApp({ apiKey, log = (entry) => process.stdout.write(JSON.stringify(entry) + '\n') }: Options) {
  if (!/^[0-9a-f]{64}$/i.test(apiKey ?? '')) {
    throw new Error('P05_API_KEY debe contener 64 caracteres hexadecimales; no se ha iniciado el servicio.');
  }
  const expectedKey = digest(apiKey);
  const app = Fastify({
    logger: false,
    bodyLimit: 4096,
    requestTimeout: 10_000,
    connectionTimeout: 10_000,
    requestIdHeader: false,
    genReqId: (req) => {
      const candidate = req.headers['x-request-id'];
      return typeof candidate === 'string' && UUID_PATTERN.test(candidate) ? candidate : randomUUID();
    },
    ajv: { customOptions: { coerceTypes: false, removeAdditional: false, useDefaults: false } },
  });

  app.addHook('onResponse', async (request, reply) => {
    log({ requestId: request.id, status: reply.statusCode, durationMs: Math.round(reply.elapsedTime * 100) / 100 });
  });
  app.setErrorHandler((error, request, reply) => {
    const code = error instanceof Error && 'statusCode' in error ? error.statusCode : undefined;
    const status = typeof code === 'number' && code >= 400 && code < 500 ? 400 : 500;
    reply.code(status).send(failure(request.id, status === 400 ? 'INVALID_REQUEST' : 'INTERNAL_ERROR',
      status === 400 ? 'La petición no es válida.' : 'No se pudo procesar la petición.'));
  });
  app.setNotFoundHandler((request, reply) => {
    reply.code(404).send(failure(request.id, 'INVALID_REQUEST', 'La ruta solicitada no existe.'));
  });
  app.get('/health', async () => ({ status: 'ok' }));
  app.post<{ Body: QuoteRequest }>('/v1/tarifas/consultar', {
    onRequest: async (request, reply) => {
      const supplied = request.headers['x-api-key'];
      if (typeof supplied !== 'string' || !timingSafeEqual(digest(supplied), expectedKey)) {
        return reply.code(401).send(failure(request.id, 'UNAUTHORIZED', 'Autenticación requerida.'));
      }
      const requestId = request.headers['x-request-id'];
      if (typeof requestId !== 'string' || !UUID_PATTERN.test(requestId)) {
        return reply.code(400).send(failure(request.id, 'INVALID_REQUEST', 'X-Request-Id debe ser un UUID válido.'));
      }
    },
    schema: {
      body: {
        type: 'object', additionalProperties: false, required: ['productCode', 'quantity'],
        properties: {
          productCode: { type: 'string', pattern: '^PROD-[0-9]{3}$' },
          quantity: { type: 'integer', minimum: 1, maximum: 10_000 },
        },
      },
    },
  }, async (request, reply) => {
    const { productCode, quantity } = request.body;
    const unitCents = catalogue.get(productCode);
    if (unitCents === undefined) {
      return reply.code(404).send(failure(request.id, 'PRODUCT_NOT_FOUND', 'El producto solicitado no existe.'));
    }
    const issuedAt = new Date();
    return {
      schemaVersion: '1', requestId: request.id, quoteId: randomUUID(),
      productCode, quantity, currency: 'EUR',
      unitPrice: money(unitCents), totalPrice: money(unitCents * quantity),
      issuedAt: issuedAt.toISOString(),
      validUntil: new Date(issuedAt.getTime() + 86_400_000).toISOString(),
      tariffVersion: 'demo-1',
    };
  });
  return app;
}
