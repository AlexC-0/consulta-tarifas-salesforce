// El endpoint se lee de un archivo local; nunca se imprime junto con la clave.
import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { postOnce } from './single-http.ts';
const file = process.argv[2];
if (!file) throw new Error('Falta el archivo local de endpoint.');
const base = new URL(readFileSync(file, 'utf8').replace(/^\uFEFF/, '').trim());
if (base.protocol !== 'https:' && !(base.protocol === 'http:' && base.hostname === '127.0.0.1')) throw new Error('Destino no permitido.');
const result = await postOnce(new URL('/v1/tarifas/consultar', base), process.env.P05_API_KEY ?? '', randomUUID());
process.stdout.write(JSON.stringify(result)+'\n');
