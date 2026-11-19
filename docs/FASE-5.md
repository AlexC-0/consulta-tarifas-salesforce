# Fase 5 — robustez temporal y verificación de fallos

Base publicada: `bece641edf2f6293a6df177327dac6697653b9a4`, posterior a fase 4
`df23ec6fcbe3305b3a2250a251a774dd6cb1033f`. La evidencia anterior se conserva en
[FASE-4](FASE-4.md) y [evidencias-fase-4.json](evidencias-fase-4.json).
El despliegue de esta fase es incremental; no acredita instalación limpia.

## Política temporal

- Recepción: hora Salesforce inmediatamente después de Http.send. Se utiliza la
  misma referencia en cliente y servicio, sin recapturarla después de validar.
- Emisión: hasta recepción + **1000 ms**, inclusive. El margen fijo de un segundo
  cubre el rechazo observado de 13 ms con un límite pequeño; no admite desfases
  arbitrarios. Pruebas deterministas: 0, 13, 999, 1000 y rechazo a 1001 ms.
- Duración: **86.400.000 ms exactos**. Diferencias de un milisegundo se rechazan.
- Caducidad: estrictamente posterior a recepción, nueva comprobación antes de DML
  y control en before insert sobre el candidato privado original. No hay gracia.
  Si caduca antes del DML: INVALID_RESPONSE; si el trigger impide insertar:
  SAVE_FAILED y rollback. No existe permiso especial de inserción para pruebas.
- Emisión y vencimiento se conservan sin desplazamientos; los campos Salesforce
  siguen teniendo la resolución de segundos comprobada en fases anteriores.
  El contrato y sus fronteras se validan con los milisegundos originales.
- No se modifica ningún reloj, NTP, precio, correlación ni regla de integridad.

La prueba de caducidad entre recepción y guardado utiliza instantes explícitos
en la función privada de validación. No se presenta como reproducción de una
carrera real dentro del DML. El control adicional del trigger está presente en
producción; las pruebas de integridad mantienen prohibiciones y aislamiento.

## Vigencia visual

El DTO añade `serverNow` y el controlador una lectura no cacheable `obtenerHora`,
protegida por el permiso funcional existente. Ninguna operación recibe fechas del
navegador para validar o guardar. El LWC avanza la referencia con performance.now().
La fecha de calendario del ordenador deja de determinar la vigencia.

La referencia recibida constituye el extremo inferior; el tiempo de ida y vuelta
medido constituye una banda conservadora de incertidumbre. Si el vencimiento cae
dentro de ella, la vista muestra «Vigencia pendiente de verificar». Solo muestra
Caducada cuando incluso el extremo inferior alcanza el vencimiento. La presentación
se denomina «Vigencia estimada»: transporte, resolución y deriva impiden precisión absoluta.

Al ocultarse la vista se invalida la referencia. Al volver a estar visible, recibir
foco, pageshow o detectar un salto de temporizadores mayor de cinco segundos, se
consulta solo Salesforce. No hay sondeo periódico al proveedor, reintento tras
error ni renovación de instantáneas. Un fallo conserva confirmación e histórico y
deja la vigencia pendiente. Las respuestas antiguas no sustituyen referencias de
un detalle posterior. Se limpian intervalos y listeners al desconectar.

## Banco de fallos aislado

El arranque normal `npm.cmd start` no importa el banco. Los archivos
`proveedor/scripts/fault-harness.ts` y `serve-faults.ts` solo se activan mediante
un comando explícito; no hay control desde el LWC ni endpoints administrativos.
El escenario se lee de un archivo local ignorado. Cada fallo inducido ocurre
después de la autenticación y validación normales. La clave persistente no cambia.

Preparar `.local/phase5/scenario.txt` con `valid` y, desde proveedor/:

```powershell
node --env-file=.env scripts/serve-faults.ts --enable-fault-tests ../.local/phase5/scenario.txt
```

Escenarios: valid, unauthorized, rate-limit, unavailable, inconsistent, expired,
future, timeout y disconnect. Solo escucha en 127.0.0.1:3055. Timeout retrasa la
respuesta 12 segundos y permite observar el límite Apex de diez segundos. Expired
y future alteran exclusivamente respuestas del banco, conservando 24 horas exactas;
no cambian el reloj ni el proveedor normal. La prueba 401 desde Salesforce es un
rechazo deliberado posterior a una autenticación válida; no acredita una clave
incorrecta en Salesforce. Esa comprobación existe por HTTP local con secreto efímero
y como evidencia histórica de fase 1B, sin repetir la sustitución de clave.

Antes de exponerlo, autorizar túnel, puerto, finalidad y duración; registrar endpoint,
ajustes y procesos propios para restaurarlos. El archivo de escenario no se sirve.
No exponer otro servicio ni cambiar el secreto para provocar fallos.

La sonda [verificar-fallo.apex](../salesforce/scripts/verificar-fallo.apex) exige una
copia local con EXPECTED_CATEGORY sustituida. Comprueba categoría, requestId,
una llamada, cero nuevas filas y hash idéntico de todos los campos históricos.
Usa el servicio: Apex anónimo no admite lanzar AuraHandledException. Los mensajes
del controlador se verifican en pruebas Apex y en el recorrido LWC.

## Capas de verificación

| Capa | Verificación de fase 5 | Límite |
| --- | --- | --- |
| Apex HttpCalloutMock | 40/40: cliente 18, servicio 14, controlador 8 | No acredita red |
| Jest | 30/30: reloj desfasado, caducidad, latencia, suspensión, carreras y limpieza | No acredita permisos ni navegador Salesforce real |
| Proveedor por inyección/contrato | 42/42 anteriores repetidas | Inyección no equivale a HTTP |
| HTTP loopback real | Una prueba adicional con 400, 401, 404, 429, 503, 200 anómalos, timeout, desconexión y recuperación | No acredita timeout Salesforce |
| TypeScript | Sin errores en fuentes y herramientas de prueba | Sin instalaciones globales |
| Salesforce real | Servicio y Named Credential existentes, destino explícito | Diagnóstico administrativo complementario |
| LWC comercial | Cuenta existente con permisos mínimos | Evidencia separada del diagnóstico administrativo |

Comandos locales desde sus respectivas carpetas:

```powershell
# salesforce/
npm.cmd run test:unit
# proveedor/
npm.cmd run check
```

Resultados de la ejecución, matriz final y restauración en [STATUS](STATUS.md).

La correlación final detectó dos recepciones con el mismo requestId ante 429 y
503, frente a un callout Apex y un envío LWC. No se atribuye una sola entrega a
esos casos. La capa que las repite no está aislada; el criterio de ausencia de
repeticiones de extremo a extremo permanece pendiente, sin añadir idempotencia.

## Archivos afectados

| Grupo | Archivos modificados |
| --- | --- |
| Raíz | `.gitignore`, `AGENTS.md`, `README.md` |
| Documentación vigente | `docs/CLIENTE_APEX.md`, `docs/CONEXION.md`, `docs/ENVIRONMENT.md`, `docs/PERSISTENCIA.md`, `docs/PROJECT_BRIEF.md`, `docs/SEGURIDAD.md`, `docs/STATUS.md`, `docs/USO.md`, `docs/openapi.json` |
| Clases en `salesforce/force-app/main/default/classes/` | `P05ConsultaTarifa.cls`, `P05ConsultaTarifaTest.cls`, `P05TarifasServicio.cls`, `P05TarifasServicioTest.cls`, `P05TarifasControlador.cls`, `P05TarifasControladorTest.cls`, `P05TarifaVista.cls` |
| LWC en `salesforce/force-app/main/default/lwc/p05Tarifas/` | `p05Tarifas.js`, `p05Tarifas.html`, `__tests__/p05Tarifas.test.js` |

| Grupo | Archivos nuevos |
| --- | --- |
| Histórico y evidencia | `docs/FASE-4.md`, `docs/FASE-5.md`, `docs/evidencias-fase-5.json`, `docs/evidencias/fase-5/detalle-sin-proveedor.png` |
| Banco y HTTP local | `proveedor/scripts/fault-harness.ts`, `proveedor/scripts/serve-faults.ts`, `proveedor/test/fault-http.test.ts` |
| Despliegue y sonda | `salesforce/manifest/fase-5.xml`, `salesforce/scripts/verificar-fallo.apex` |
