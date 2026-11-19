# Fase 5B — Diagnóstico de recepciones repetidas

Base publicada: `3f6a4dcd9aa08ce3884a78ef9dc252cf684ede16`. Ejecución del
19/11/2026. **V1 no cerrada**. El [estado de fase 5](ESTADO-FASE-5.md) conserva
su contexto anterior a publicación; sus pruebas no se atribuyen a esta ejecución.

## Recuento y evidencia inicial

El recolector de fase 5 calculaba `receivedRequests = max(hooks, respuestas)` y
`singleDelivery = receivedRequests == 1`. No sumaba ambos tipos de evento, pero
tampoco tenía identificador independiente por entrada HTTP. Por tanto, ese campo
era una estimación por eventos, no una prueba autónoma de recepciones distintas.

El registro original contiene 47 líneas y cuatro líneas de hook repetidas
literalmente. Cada grupo 429/503 administrativo y comercial contiene dos hooks y
dos respuestas con duraciones diferentes. No son dos copias idénticas del bloque
completo. Se conserva la observación original; seis cadenas mal codificadas de
[evidencias-fase-5.json](evidencias-fase-5.json) se reparan sin alterar resultados,
claves, números ni booleanos.

La instrumentación nueva es opcional y exclusiva del banco aislado:

- `http-entry`: UUID local nuevo por objeto HTTP `IncomingMessage`, independiente
  del `requestId` de correlación.
- `fault-hook`: ejecución del fallo controlado después de autenticación y validación.
- `http-response`: respuesta final con estado y duración monotónica.
- `http-aborted`: cierre antes de completar la escritura, si ocurre.

Cada evento tiene `runId`, secuencia creciente, fecha UTC y `receptionId`. El
resumen cuenta entradas distintas, separa hooks/respuestas y rechaza secuencias
duplicadas o eventos sin entrada. No registra cuerpos, claves, cookies, cabeceras,
direcciones IP ni datos personales. La evidencia publicada contiene resúmenes por
recepción, no los registros completos.

Se verificó un único listener propio en `127.0.0.1:3055`, inicialmente libre.
Un solo proceso del banco y un archivo nuevo se usan para A/B/C. Todas las
operaciones tienen correlaciones nuevas, escenarios fijos hasta terminar y una
sola lectura del registro. La secuencia y las identidades permiten descartar
lecturas duplicadas, mezcla de ejecuciones y dos eventos contados como peticiones.

## Comparación controlada

Mismo producto PROD-001, cantidad 3, clave existente, ruta y banco durante toda la
matriz. El 401 es inducido después de autenticación correcta; no se cambia la clave.
La prueba local adicional con clave efímera incorrecta distingue entrada/respuesta
de ejecución del hook: 1/0/1.

| Capa | Cambio respecto a la anterior | Ejecución |
| --- | --- | --- |
| A | Base en loopback | Node HTTP, un `request` y un `end` |
| B | Transporte por HTTPS del túnel | El mismo cliente, cuerpo y banco |
| C | Cliente y origen de la llamada: Apex/Named Credential P05 | Una llamada a `consultarDemo`, sin servicio de persistencia |
| D | No ejecutada | LWC innecesario: C reproduce el hallazgo y no cambia código comercial |

El cliente Node usa `http`/`https.request`, `agent:false`, sin bucles, seguimiento
de redirecciones ni manejador que vuelva a enviar. Cuenta una asignación de socket
por operación; consume la respuesta y destruye la solicitud tras diez segundos.
La [referencia Node 24.13.0](https://nodejs.org/download/release/v24.13.0/docs/api/http.html)
describe el agente de un solo uso y muestra los reintentos mediante llamadas
explícitas del programa. La configuración y los recuentos A/B verifican el cliente
efectivamente utilizado; no se presupone el comportamiento de otros clientes HTTP.

La sonda [diagnostico-recepciones.apex](../salesforce/scripts/diagnostico-recepciones.apex)
invoca una vez el cliente existente y verifica `Limits.getCallouts() == 1`, cero
DML y hash de todos los campos de las instantáneas antes/después. El cliente
contiene un único `Http.send`; genera UUID nuevo en cada invocación. Dos entradas
con el mismo UUID en esta sonda no son dos invocaciones independientes de ese método.
El LWC conserva su única llamada y su bloqueo mientras guarda; no interviene en C.

Resultados y tiempos por intento en [STATUS](STATUS.md); correlaciones, secuencias,
estados y tiempos de cada recepción en [evidencias-fase-5b.json](evidencias-fase-5b.json).
Se repitieron solamente 429 y 503 de C una vez por estado para confirmar el patrón.
Los tiempos Node incluyen transporte y consumo del cuerpo; los de Apex abarcan
el método cliente y validación. No son una medición de rendimiento comparable.

## Conclusión y alcance

**429/503 producen dos entradas HTTP reales por una operación y un callout Apex.**
Cada entrada tiene identidad propia, hook y respuesta completa del mismo estado.
A/B producen una entrada en todos los controles; C produce una en 200/401. El banco
no transforma un único evento en dos entradas y el túnel no duplica sistemáticamente
429/503 con el cliente Node.

La divergencia queda acotada al recorrido externo activado por `Http.send` desde
Salesforce mediante Named Credential hasta la entrada del proveedor, incluida su
interacción con el túnel. No hay observación intermedia en la salida Salesforce o
en el borde del túnel que permita asignar la repetición a Salesforce, Named
Credential o Cloudflare por separado. Cambiar de origen implica diferencias de
transporte y cabeceras administradas; B no exonera universalmente al túnel.
El patrón es compatible con un reenvío externo, pero su mecanismo interno no se
ha demostrado. No se ha encontrado un reintento ni doble invocación en código propio.

El [ciclo de Fastify](https://fastify.dev/docs/latest/Reference/Lifecycle/) separa
entrada, `onSend` y `onResponse`, coherentemente con la instrumentación. Los métodos
documentados de [HttpRequest](https://developer.salesforce.com/docs/platform/apex-ref/references/apex-ref/apex-classes-restful-http-httprequest.html)
no exponen un ajuste específico de reintentos. El
[glosario de Named Credentials](https://developer.salesforce.com/docs/platform/named-credentials/references/named-credentials-reference/nc-glossary.html)
define endpoint y autenticación, sin describir aquí una opción para esta repetición.
En esas referencias no se localizó una opción específica y reversible que resuelva
el hallazgo; esto no demuestra que no exista en otros niveles de plataforma.

Cloudflare documenta [`--retries`](https://developers.cloudflare.com/tunnel/reference/run-parameters/)
para errores de conexión/protocolo. No acredita que controle una segunda solicitud
tras respuestas HTTP completas 429/503, por lo que no se cambia ese parámetro ni se
presenta como solución. No se extrapolan reglas de otros productos Salesforce.

La garantía verificable es **ausencia de reintentos programados en la aplicación**,
no entrega única de extremo a extremo. Se propone esa delimitación para revisión;
no sustituye silenciosamente el criterio de aceptación. No se añaden idempotencia,
colas, cachés, deduplicación ni códigos 200 artificiales. La corrección realizada
consiste en hacer verificable el recuento y reparar la codificación documental.

Si se mantiene la exigencia de entrega única, el siguiente paso concreto es obtener
una traza correlacionada de salida Salesforce y entrada del borde del túnel, o una
explicación del transporte por su soporte técnico. Requiere acceso adicional fuera
de esta fase; no se han enviado comunicaciones. Cambiar infraestructura o introducir
idempotencia sería otro alcance y tampoco demostraría una única entrega física.

## Reproducción y verificaciones

Desde `proveedor`, usando herramientas instaladas:

```powershell
npm.cmd run typecheck
node --test test/reception-diagnostics.test.ts test/fault-http.test.ts
```

Resultado: TypeScript correcto y 3/3 pruebas. Cubren separación de eventos,
identidades distintas con correlación compartida, lectura duplicada rechazada,
autenticación previa al fallo y la matriz HTTP anterior. No se repiten las suites
completas de Apex/Jest ni se atribuyen a fase 5B sus resultados históricos.

El banco requiere activación explícita, un archivo local con escenario y
`--trace-receptions`; sigue fuera de `npm start`. El cliente diagnóstico recibe
un archivo local con endpoint, sin publicarlo. Antes de otra reproducción externa
se requiere una nueva ventana de túnel, verificación P05 y respaldo del endpoint.
La sonda Apex sustituye `EXPECTED_STATUS` únicamente en una copia local y utiliza
destino explícito `p05-tarifas-dev`. No necesita desplegar clases.

No cambia código productivo Apex/LWC/proveedor, dependencias, permisos, relojes,
secreto ni principal. El único ajuste temporal Salesforce es el endpoint de la
Named Credential existente, restaurado tras las comprobaciones. Conservación,
cierre de procesos y duración constan en [STATUS](STATUS.md).

La preparación del cierre V1 exige revisar expresamente la garantía externa y
comprobar o resolver el criterio de instalación limpia. Esta fase permite preparar
esa revisión técnica, pero no acreditar todavía el cierre V1 con entrega única.
