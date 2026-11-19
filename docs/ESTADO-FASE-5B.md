# Estado — fase 5B diagnosticada, 19/11/2026

**Se confirman dos entradas HTTP distintas ante 429/503 por una operación y un
callout Apex.** Los controles con Node, tanto en loopback como por el mismo túnel
HTTPS, reciben una entrada por estado. La divergencia queda acotada al recorrido
externo de la llamada Apex; su componente interno no está identificado.
No se ha demostrado un reintento o doble invocación en código propio.

**V1 no cerrada.** La garantía demostrada es ausencia de reintentos programados en
la aplicación. No equivale a entrega única de extremo a extremo. Esa delimitación
se presenta para revisión y no cambia el criterio de aceptación automáticamente.

## Base y cambios

Repositorio P05, raíz y remoto comprobados, rama main, estado inicial limpio.
Fase 5 publicada en **3f6a4dcd9aa08ce3884a78ef9dc252cf684ede16**. Los cambios de
fase 5B están preparados sin staging, commit ni push. Remoto e historial intactos.

- Banco aislado: instrumentación opcional por entrada, hook y respuesta; cliente
  diagnóstico de un solo envío y pruebas de recuento.
- Sonda Apex anónima de diagnóstico, sin DML ni despliegue de clases.
- [FASE-5B](FASE-5B.md), [evidencias nuevas](evidencias-fase-5b.json), README e
  instrucciones locales actualizados.
- [Estado histórico de fase 5](ESTADO-FASE-5.md) conservado íntegro. Su base anterior
  a publicación describe aquella ejecución, no el HEAD actual.
- Seis textos mal codificados reparados en [evidencias-fase-5.json](evidencias-fase-5.json),
  sin cambiar resultados. El código productivo Apex/LWC/proveedor no cambia.

## Matriz real

Una operación por fila. A/B: un request, un end, una asignación de socket y
cero reintentos programados. C: una invocación del cliente y un callout Apex.
Entradas, hooks y respuestas se cuentan por separado; no se suman como solicitudes.

| Capa | HTTP | Operaciones | Callouts Apex | Entradas | Hooks | Respuestas | Tiempo operación ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| A · loopback | 200 | 1 | — | 1 | 1 | 1 | 39,69 |
| A · loopback | 401 | 1 | — | 1 | 1 | 1 | 27,38 |
| A · loopback | 429 | 1 | — | 1 | 1 | 1 | 24,26 |
| A · loopback | 503 | 1 | — | 1 | 1 | 1 | 28,18 |
| B · HTTPS | 200 | 1 | — | 1 | 1 | 1 | 300,64 |
| B · HTTPS | 401 | 1 | — | 1 | 1 | 1 | 159,4 |
| B · HTTPS | 429 | 1 | — | 1 | 1 | 1 | 147,43 |
| B · HTTPS | 503 | 1 | — | 1 | 1 | 1 | 142,68 |
| C · Apex | 200 | 1 | 1 | 1 | 1 | 1 | 396 |
| C · Apex | 401 | 1 | 1 | 1 | 1 | 1 | 194 |
| C · Apex | 429 | 1 | 1 | 2 | 2 | 2 | 1351 |
| C · Apex | 503 | 1 | 1 | 2 | 2 | 2 | 1304 |
| C · confirmación | 429 | 1 | 1 | 2 | 2 | 2 | 1376 |
| C · confirmación | 503 | 1 | 1 | 2 | 2 | 2 | 1230 |

Total: 14 operaciones, 6 callouts Apex y 18 entradas HTTP distintas. Las segundas
entradas aparecen 1184/1130 ms después de las primeras en C 429/503 y 1101/1090 ms
en la confirmación. Son observaciones temporales, no prueba de un algoritmo interno.
Cada recepción termina con el estado esperado. Registro nuevo con un único runId,
54 eventos, secuencias 1–54 sin duplicados y sin eventos ajenos a los 14 intentos.

Cinco instantáneas antes y después de la ejecución. Las seis operaciones C verifican
individualmente cinco antes/cinco después, hash histórico idéntico y cero DML.
A/B llaman directamente al proveedor, que no persiste en Salesforce. El 200 de C
usa el cliente sin servicio de guardado. No se crean nuevas instantáneas.

El 401 de la matriz es inducido tras autenticar con la clave existente. La prueba
local de clave incorrecta usa una clave efímera y obtiene entrada/hook/respuesta
1/0/1. No se modifica el secreto persistente. D/LWC no se repite: C reproduce el
hallazgo sin cambiar código comercial ni necesitar Login As.

## Hipótesis y garantías

| Hipótesis | Resultado |
| --- | --- |
| Sumar hook y respuesta como dos solicitudes | Descartada: el recolector anterior usaba máximo, no suma |
| Logs duplicados, reutilizados o procesos mezclados | Descartada para la ejecución nueva: archivo nuevo, proceso único, UUID de recepción y secuencia continua |
| Dos eventos de una sola entrada HTTP | Descartada: cada repetición tiene dos objetos HTTP e identidades distintas |
| Reintento en cliente diagnóstico | No encontrado; un envío/socket y una entrada en cada control A/B |
| Doble invocación Apex o LWC propia | C usa una invocación, un callout y correlación común; LWC no interviene |
| Túnel duplica siempre 429/503 | No reproducida con Node: B recibe una entrada |
| Componente externo concreto causante | No identificado; falta observación intermedia de salida Salesforce/borde del túnel |

La documentación consultada no aporta una opción específica y reversible demostrada
para evitar estas repeticiones. El ajuste de reintentos de cloudflared se documenta
para errores de conexión/protocolo y no se modifica como supuesto remedio de
respuestas HTTP completas. Fuentes y límites de inferencia en [FASE-5B](FASE-5B.md).

Corrección limitada al diagnóstico: identificador independiente por recepción y
recuento verificable. No se añade idempotencia, caché, cola, reintento ni deduplicación;
429/503 mantienen sus estados y categorías. La observación original se conserva.

## Pruebas, conservación y restauración

- TypeScript correcto. **3/3 pruebas afectadas**, cero fallos: dos de diagnóstico y
  la matriz HTTP previa. Son pruebas automatizadas locales, separadas de A/B/C.
- Apex/Jest completos no repetidos. 40/40 Apex, 30/30 Jest y 43/43 proveedor son
  resultados históricos de fase 5, no pruebas nuevas de fase 5B.
- P05-000000 a P05-000004 conservadas; correlaciones e importes coinciden con la
  evidencia histórica. Campos completos intactos en cada comparación Apex.
- Endpoint inicial restaurado y metadata de Named Credential idéntica en lectura
  posterior. Secreto y principal sin cambios. Dos ajustes temporales de endpoint;
  cero componentes de aplicación desplegados.
- Proveedor y túnel propios detenidos. Puerto 3055 libre. Túnel abierto **3,78 minutos**,
  dentro de los 30 autorizados. Login As no utilizado ni modificado.
- Sin cambios de relojes, configuración global, permisos, usuarios u organizaciones.
- Diff sin errores de espacios; 13 JSON válidos y 97 enlaces relativos comprobados.
  Sin secretos, URLs de acceso ni endpoint temporal en los archivos revisados.
  Codificación y redacción verificadas; cero archivos en staging.

## Pendientes para V1

1. Revisar expresamente si el alcance admite ausencia de reintentos de aplicación
   sin prometer entrega única. No se da por aceptada esa delimitación.
2. Si se mantiene entrega única, obtener trazas intermedias o explicación del
   transporte mediante soporte antes de atribuir causa o proponer configuración.
   No se han enviado comunicaciones ni sustituido infraestructura.
3. Comprobar la instalación limpia desde cero dentro de un alcance autorizado;
   continúa pendiente y no se confunde con el despliegue incremental previo.

Se puede preparar la revisión del cierre con estas evidencias y decisiones pendientes.
No se recomienda aprobar todavía el cierre V1 con el criterio de entrega única.
