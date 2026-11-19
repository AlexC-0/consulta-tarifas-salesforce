# Estado — fase 5 implementada, 19/11/2026

Robustez temporal desplegada y matriz de fallos ejecutada. **V1 no cerrada ni
presentada como candidata a cierre**: ante HTTP 429 y 503 se observaron dos
peticiones al proveedor con el mismo requestId, aunque Apex realizó un callout y
el LWC un envío. Falta aislar la capa que repite esas entregas y resolver o delimitar
ese criterio. La instalación limpia continúa sin comprobarse.

## Base y cambios

Rama `main`, remoto `origin` de este repositorio, HEAD
`bece641edf2f6293a6df177327dac6697653b9a4`, posterior a fase 4
`df23ec6fcbe3305b3a2250a251a774dd6cb1033f`. Cambio inicial pendiente:
`docs/openapi.json`; su descripción se integró con redacción técnica neutral.
Sin staging, commits, push, cambios de remoto o historial.

- Cliente Apex: margen fijo de emisión de 1000 ms, recepción única al retornar
  Http.send, 24 horas exactas y ninguna tolerancia de caducidad.
- Servicio: conserva esa recepción y comprueba vigencia antes del DML y en el
  trigger. Fechas originales sin desplazamiento; USER_MODE e integridad conservados.
- DTO/controlador/LWC: hora de Salesforce, avance monotónico, banda de incertidumbre
  por latencia, invalidación al ocultar y referencia nueva al reanudar. Sin sondeo
  al proveedor ni renovación de instantáneas.
- Banco de fallos aislado, activación explícita y archivo de control local; el
  arranque normal no lo importa. Clave persistente y permisos intactos.
- Contrato, instrucciones y documentación actualizados. El estado de fase 4 se
  conserva íntegro como [FASE-4](FASE-4.md); no se atribuye su evidencia a esta versión.

Decisiones, límites temporales y comandos en [FASE-5](FASE-5.md),
[CLIENTE_APEX](CLIENTE_APEX.md) y [USO](USO.md).

## Despliegue y pruebas finales

| Comprobación nueva | Resultado |
| --- | --- |
| manifest/fase-5.xml, API 68.0 | Succeeded, ocho componentes, cero errores |
| P05ConsultaTarifaTest | 18/18 |
| P05TarifasServicioTest | 14/14 |
| P05TarifasControladorTest | 8/8 |
| Total Apex sobre código final | **40/40** |
| Jest sobre LWC final | **30/30** |
| Proveedor: inyección/contrato + HTTP real | **43/43**: 42 anteriores repetidas y una matriz HTTP adicional |
| TypeScript | Correcto, incluidas herramientas del banco |
| Contrato tras cambio documental de OpenAPI | 3/3, incluidas en las 42; no se suman como pruebas distintas |

Siete clases existentes y el LWC desplegados; no se desplegaron permisos, esquema,
aplicación, pestaña ni credenciales con el manifiesto de fase 5. Identidad del destino
contrastada con Organization y con requestId/importes de P05-000000 y P05-000001.
Destino explícito `p05-tarifas-dev` en cada operación. Instalación incremental.

Jest verifica fronteras de caducidad, relojes locales adelantados/atrasados, latencia,
respuestas tardías, suspensión de temporizadores, visibilidad, deduplicación y limpieza.
Apex verifica límites de 999/1000/1001 ms, duración exacta ±1 ms, caducidad sin gracia,
revalidación al guardar, permisos, aislamiento e integridad. Las fronteras deterministas
no se presentan como una carrera física de DML ni como una espera real de 24 horas.

## Matriz de fallos y capas de evidencia

Todas las columnas de esta tabla corresponden a comprobaciones **nuevas**, salvo
la referencia histórica explícita de autenticación. Mocks y HTTP local no acreditan
por sí solos llamadas desde Salesforce ni recorrido comercial.

| Caso | Unitaria/mock | HTTP local real | Salesforce real | LWC comercial real |
| --- | --- | --- | --- | --- |
| Consulta válida | Apex/Jest | 200 coherente | P05-000002, 1 petición | P05-000003, 1 envío y 1 petición |
| Entrada inválida | Sin callout ni DML | 400 al enviar cuerpo inválido directamente | Cubierto en Apex | Cantidad 0, cero envíos |
| Producto inexistente | 404 y sin insert | 404 | PROD-999, 1 petición, cero filas | No se expone el fixture en selector; no repetido desde UI |
| Autenticación rechazada | UNAUTHORIZED seguro | Clave efímera incorrecta: 401 | 401 inducido tras autenticar, 1 petición | Mensaje seguro, 1 envío y 1 petición |
| HTTP 429 | RATE_LIMITED | 429, 1 petición | 1 callout, **2 peticiones recibidas** | 1 envío, **2 peticiones recibidas** |
| Error 5xx | 500 y 503 | 503, 1 petición | 503: 1 callout, **2 peticiones recibidas** | 1 envío, **2 peticiones recibidas** |
| 200 incoherente | INVALID_RESPONSE | 200 con total incorrecto | Rechazo, 1 petición, cero filas | Mensaje seguro y resultado anterior retirado |
| Tarifa caducada | Rechazo sin gracia | 200 con 24 h exactas, ya vencida | Rechazo, 1 petición, cero filas | Rechazo visible, sin éxito anterior |
| Emisión fuera de margen | 1001 ms rechazado | 200 con emisión +60 s | Rechazo, 1 petición, cero filas | Rechazo visible, sin éxito anterior |
| Timeout | Mock, separado de red | Cliente espera 10 s reales | TIMEOUT real ante demora de 12 s | TIMEOUT real, 1 envío, 1 petición recibida |
| Conexión interrumpida | CONNECTION_ERROR/HTTP_ERROR | Socket cerrado y listener detenido | El túnel devuelve HTTP_ERROR; 1 petición recibida | Mensaje HTTP seguro y cero filas |
| Proveedor/túnel cerrados | Histórico sin callout | Conexión local rechazada | Lectura histórica con cero callouts | Error seguro de indisponibilidad; histórico y detalle siguen legibles |
| Recuperación posterior | Controles recuperados | Nuevo 200 | P05-000003 tras fallos del servicio | P05-000004 tras los ocho fallos comerciales |
| Histórico/detalle sin proveedor | Apex/Jest, incluido histórico caducado | No aplica | P05-000002 legible, cero callouts | Recarga, actualización y P05-000004 antes/después del error |
| Reanudación de vigencia | Jest: referencia nueva, latencia y carreras | No aplica | obtenerHora, sin proveedor | Eventos oculta→visible registrados; «Vigente» confirmado visualmente |

En los ocho fallos comerciales se contrastaron mensaje seguro, UUID, un envío,
retirada de confirmación/detalle anteriores y conservación de los campos de todas
las instantáneas mediante lectura administrativa. Ningún fallo creó registros.
Las sondas administrativas también compararon los campos históricos y el contador
Apex. Ese contador no equivale al número de peticiones que recibe el proveedor.

**Hallazgo pendiente:** 429 y 503 producen dos pares de eventos de proveedor, con
el mismo UUID y duraciones distintas, tanto desde Apex anónimo como desde el LWC.
El banco HTTP local recibe una sola petición por caso. No hay bucles de reintento
en Apex o JavaScript; la capa causante dentro del recorrido externo no está aislada.
No se acredita ausencia de repeticiones de extremo a extremo ni se añade idempotencia
para ocultarlas. Los demás casos correlacionados tienen una sola recepción.

El 401 real de esta fase es un rechazo controlado después de autenticar. No se
sustituyó la clave persistente. La clave incorrecta real se verifica por HTTP local;
la evidencia Salesforce 200→401→200 de [fase 1B](evidencias-fase-1b.json) se conserva
como histórica, sin atribuirla al código nuevo.

Dos sondas preliminares no se contabilizan como éxitos: AuraHandledException no
puede lanzarse desde Apex anónimo; una desconexión del origen produjo HTTP_ERROR
a través del túnel, en lugar de CONNECTION_ERROR. Las sondas finales usan el servicio
y la categoría observada. Los clics comerciales se activaron mediante eventos DOM
en los controles existentes, sin sustituirlos por invocaciones Apex administrativas.

[Evidencia saneada y correlaciones](evidencias-fase-5.json).
[Captura limitada al componente tras fallo y lectura offline](evidencias/fase-5/detalle-sin-proveedor.png).

## Conservación y restauración

| Instantánea | Función | Estado |
| --- | --- | --- |
| P05-000000 | Administrativa, fase 3 | Conservada |
| P05-000001 | Comercial, fase 4 | Conservada |
| P05-000002 | Consulta administrativa válida de fase 5 | Conservada |
| P05-000003 | Guardado comercial de fase 5 | Conservada; propietario y autoría comprobados |
| P05-000004 | Recuperación comercial de fase 5 | Conservada; propietario y autoría comprobados |

Cinco registros finales, dos administrativos y tres comerciales; 59,70 EUR cada
uno para PROD-001 × 3. Ningún borrado ni actualización de instantáneas. Cuenta
comercial existente y tres conjuntos P05 conservados; cero permisos amplios en
la lectura final de perfil y asignaciones. Sin usuarios u organizaciones nuevos.

Proveedor y túnel propios detenidos tras **14,82 minutos**, dentro de los 45
minutos autorizados; puerto 3055 sin listener. Endpoint inicial restaurado y metadata
de Named Credential idéntica a la inicial. Secreto y principal sin cambios.

Sesión comercial cerrada mediante su enlace oficial. Ese cierre terminó también
la sesión administrativa del navegador. Login As se restauró mediante Metadata API,
con la CLI P05 existente: **false**, comprobado por lectura posterior de SecuritySettings.
El único cambio de restauración fue enableAdminLoginAsAnyUser true→false; los demás
ajustes coinciden con los recuperados antes de restaurar. No se automatizó otro login.
Sesión Playwright de prueba desconectada, sin cerrar pestañas ajenas.

Sin cambios de reloj o NTP. Vigencia al reanudar: eventos de visibilidad registrados
automáticamente y texto «Vigente» comprobado visualmente de forma manual; esa
observación se distingue de las aserciones Jest y no acredita precisión absoluta.

## Criterios V1 y siguiente paso

| Criterio | Estado |
| --- | --- |
| Tres productos, cantidad entera 1–10000 y EUR | Verificado |
| Precio fijo positivo, precisión y total exacto; sin ampliaciones comerciales | Verificado |
| 24 horas exactas, margen acotado de emisión y caducidad sin gracia | Verificado |
| Valores obtenidos en servidor, sin confiar en importes del navegador | Verificado |
| Éxito guarda instantánea; error no guarda | Verificado |
| Histórico propio e inmutable, sin renovación ni proveedor | Verificado |
| USER_MODE, CRUD/FLS, mínimos e integridad | Suites finales correctas; permisos conservados |
| Vigencia independiente del reloj de calendario del navegador | Jest y referencia Salesforce; reanudación real comprobada |
| Timeout inicial de diez segundos | Verificado por mock, HTTP local y Salesforce real por separado |
| Ausencia de reintentos en código de aplicación | Verificada |
| Ausencia de entregas repetidas en el recorrido completo | **Pendiente: 429 y 503** |
| Instalación incremental | Verificada |
| Instalación limpia desde cero | **No ejecutada** |

Siguiente paso: revisar el diff y las evidencias; aislar la repetición de entregas
429/503 antes de proponer el cierre V1. La instalación limpia mantiene su límite
explícito. No hay publicación ni cierre definitivo. No introducir nuevos reintentos,
idempotencia, pedidos, pagos, reservas o descuentos como parte de esa revisión.

## Revisión local

108 archivos versionables revisados: 12 JSON y 37 XML válidos, 82 enlaces relativos
existentes. Diff sin errores de espacios; índice Git vacío. Escaneo en memoria sin
clave persistente, endpoint temporal ni enlaces reutilizables de autenticación en
archivos versionables. Captura nueva limitada al componente y revisada visualmente.
31 archivos afectados: 22 modificados y nueve nuevos; secretos, metadata temporal,
sesiones y registros de herramientas permanecen en directorios ignorados.
