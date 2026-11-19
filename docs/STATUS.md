# Estado — fase 2 completada, 19/11/2026

Tres productos operativos, cliente Apex parametrizable y demostración real de
los tres productos y del 404. Sin Product2, persistencia, instantáneas ni LWC.

## Estado inicial y Git

Ruta: `C:\Users\kaosk\source\repos\consulta-tarifas-salesforce`.
Rama main; origin propio: https://github.com/AlexC-0/consulta-tarifas-salesforce.git.
Inicio limpio; HEAD y origin/main en `679182be305255b0c411c15d0a6dd72b40df4487`,
sesión 1B publicada por Alex. No había cambios locales que preservar.

La organización P05 y sus credenciales ya existían. Se verificó de nuevo
Organization contra la identidad previamente autorizada, usando
`--target-org p05-tarifas-dev`. Developer Edition, IsSandbox=false, API 68.0.
No se crearon organizaciones ni se rehízo la autenticación.

Los cambios de fase 2 quedan sin staging. Codex no realiza commits ni push
y no ha modificado P01–P04. [Histórico completo de sesión 1B](SESION-1B.md)
y [evidencia anterior](evidencias-sesion-1b.json) conservados.

## Cambios y decisiones

- Catálogo de ejecución en proveedor/src/app.ts, en céntimos:
  PROD-001=1990, PROD-002=12550, PROD-003=99. Sin base de datos ni administración.
- Operación interna consultar(String, Decimal), con formato, rango y fracción
  comprobados antes del callout. Integer solo después de validar; sin redondeos
  silenciosos. consultarDemo() delega en ella.
- Sin lista local de códigos ni precios en Apex. Se validan correspondencia
  con petición, tipos, importes, total, identificadores, fechas y duración.
- schemaVersion permanece "1". tariffVersion admite cadenas no vacías de hasta
  64 caracteres, no solo espacios, sin exigir "demo-1".
- Se conservan currencyCode interno, timeout de 10 s, ausencia de reintentos,
  clasificación de errores y rechazo de fechas futuras.
- Contrato y ejemplos actualizados. Ajv 8.20.0, ya presente transitivamente,
  declarado como dependencia directa de desarrollo para los tests del contrato.
  Sin nuevas dependencias de ejecución ni herramientas globales.
- AGENTS actualizado al alcance de fase 2. Detalle en [CLIENTE_APEX](CLIENTE_APEX.md).

## Pruebas y despliegue

| Comprobación | Resultado real |
| --- | --- |
| npm.cmd run check | TypeScript correcto; **42/42 pruebas**, 0 fallidas |
| Contrato OpenAPI | Ejemplos y respuestas por inyección de catálogo/404/401; tipos, versiones y precisión comprobados |
| npm.cmd run smoke | HTTP loopback: tres productos 200, desconocido 404, health 200 y dos rechazos 401 |
| Despliegue de clases con RunSpecifiedTests | Succeeded: **2 componentes**, 0 errores |
| P05ConsultaTarifaTest | **16 ejecutadas, 16 aprobadas, 0 fallidas** |
| Actualización de Named Credential | Succeeded: **1 componente**, solo cambio de URL temporal |
| Demostración desde consulta-catalogo.apex | Cuatro llamadas reales, correlación verificada y cero DML |

Las 42 pruebas incluyen las 27 anteriores y los casos nuevos; se ejecutaron de
nuevo porque cambió el proveedor. Los mocks no sustituyen la prueba de red.
No se repitió la sustitución de clave protegida de sesión 1B: autenticación intacta,
sin indicios de fallo. Los dos 401 del smoke emplean una clave efímera local.

## Evidencia real Apex → HTTPS

| Producto | Cantidad | Resultado | requestId |
| --- | --- | --- | --- |
| PROD-001 | 3 | 200; 59.70 EUR | 46ca534b-0f9b-4a7f-a58d-c16b50bc53ad |
| PROD-002 | 2 | 200; 251.00 EUR | d5d7e646-b349-4094-90ca-037a6bf0126e |
| PROD-003 | 7 | 200; 6.93 EUR | 5fec0429-7562-4ff3-92e9-3b9c0cc9bda6 |
| PROD-999 | 1 | PRODUCT_NOT_FOUND / 404 | ce7393b8-b141-4aab-9d74-2ea1eb62ba16 |

Cada requestId aparece exactamente una vez en el log mínimo del proveedor con el
estado esperado. Importes, UUID y duración exacta de 24 horas validados.
El 404 se captura como excepción controlada; no se presenta como tarifa válida.
[Evidencia saneada completa](evidencias-fase-2.json).

Perfil del usuario consultado de nuevo: **System Administrator**, UserType Standard.
Esta demostración no acredita permisos del futuro comercial.

## Autorización y cierre

Alex autorizó expresamente el nuevo Quick Tunnel de fase 2 exclusivamente hacia
127.0.0.1:3055 durante la demostración. Binding comprobado en loopback.
Se reutilizaron .env, clave protegida, principal y permisos.
Solo se desplegó la Named Credential con la nueva URL; no se versiona esa URL.

Los cuatro casos funcionaron sin cambios del reloj.
Proveedor y túnel propios detenidos comprobando PID, ejecutable y binding;
cero listeners en 3055. Las credenciales quedan válidas, con endpoint temporal
inactivo hasta una nueva demostración autorizada.

No hay bloqueos de fase 2. Siguiente paso: revisión y publicación manual de Alex.
Persistencia, Product2, seguridad comercial y LWC requieren sus siguientes encargos.

## Revisión local final

37 archivos versionables revisados: ocho JSON/plantillas, seis XML/plantillas,
tres scripts PowerShell y 22 enlaces relativos correctos. Sin coincidencias de
la clave local, ID/dominio/usuario privado ni endpoint temporal en esos archivos;
comparación en memoria, sin mostrar valores. .env, .local y .sf excluidos de Git.
Histórico de sesión 1B contrastado íntegramente con STATUS del commit base.
Conversión DX local final correcta (estado 0); git diff --check sin errores.
Staging vacío y HEAD/origin/main conservados en 679182b.

Se retiraron once archivos temporales propios de esta ejecución: logs, PID,
endpoint materializado y respuestas completas de despliegue. Se conservan la
clave existente, originales, herramientas, conversión local y evidencia saneada.
No se guardaron logs de depuración Apex completos.