# Estado — sesión 1, 19/11/2026

**Base local implementada y comprobada. Conectividad real Salesforce pendiente.**
No se declara V1 terminada ni callout Salesforce exitoso.

## Repositorio e inspección

Ruta: `C:\Users\kaosk\source\repos\consulta-tarifas-salesforce`.
Git: `main`, remoto `origin` propio:
`https://github.com/AlexC-0/consulta-tarifas-salesforce.git`.
Base publicada por Alex: `b551dad` (`Initial commit`).
Al retomar: árbol limpio, solo .gitattributes; contenido conservado sin cambios.
Se comprobaron instrucciones en la carpeta y ancestros; no había AGENTS.md de P05.
Se añadió AGENTS.md específico. No se ha modificado P04 ni otros proyectos.

Entrega sin staging, nuevos commits ni push. Alex revisa y publica manualmente.

## Implementación

- API Fastify/TypeScript con PROD-001 a 19.90 EUR y cantidades enteras 1–10.000.
- Autenticación antes del cuerpo, secreto obligatorio, comparación de hashes de
  longitud fija, validación estricta sin coerción ni eliminación de campos adicionales.
- Cálculo en céntimos enteros, UUID de correlación y tarifa, vigencia exacta de 24 horas.
- Logs limitados a requestId, estado y duración. UUID inválidos no se reflejan.
- Loopback 127.0.0.1:3055; /health mínimo; sin archivos estáticos, base de datos ni túnel automático.
- Cliente P05ConsultaTarifa: petición fija de tres unidades, Named Credential,
  timeout 10 s, validación de respuesta, errores controlados, sin DML ni reintentos.
- Ocho métodos HttpCalloutMock preparados en P05ConsultaTarifaTest.
- Plantillas DX sin versión inventada; script para materializarlas tras consultar
  la versión disponible en P05. No se generó un paquete desplegable con versión supuesta.
- OpenAPI, instrucciones de conexión y generación local del secreto para Alex.
- cloudflared portable 2026.11.1 en .local/ (ignorado); sin instalación global.

## Comprobaciones ejecutadas

| Comando/comprobación | Resultado real |
| --- | --- |
| git rev-parse, branch, remote, status | P05 independiente, main, origin propio; limpio al inicio |
| Versiones y plugins CLI | Registrados en ENVIRONMENT; sin actualización global |
| sf org list --skip-connection-status --json, salida filtrada en memoria | No hay alias P05; no se contactó con otras organizaciones |
| npm install --ignore-scripts --no-fund --no-audit | 51 paquetes locales; package-lock.json creado |
| npm run check | tsc sin errores; **27/27 pruebas Node/Fastify**, sin fallos ni omisiones |
| npm run smoke | HTTP loopback real: health 200, tarifa 200, clave ausente 401, incorrecta 401; proceso cerrado |
| npm ls --depth=0 | Versiones exactas documentadas |
| npm audit --omit=dev --audit-level=high | 0 vulnerabilidades notificadas en dependencias de ejecución |
| OpenAPI con Ajv 2020 instalado transitivamente | JSON y referencias internas válidos; petición y respuestas reales 200/401 conformes a esquemas |
| Parser PowerShell | Dos scripts sin errores de sintaxis; no se generó el secreto persistente |
| git check-ignore | .env, node_modules, .local y autorizaciones Salesforce excluidos; .env.example versionable |
| Revisión local de archivos | JSON, enlaces relativos, espacios, conflictos y patrones comunes de secretos revisados |
| cloudflared --version | 2026.11.1; checksum SHA256 del binario contrastado con release oficial |

La comprobación OpenAPI no equivale a una certificación integral de toda la
especificación. La revisión por patrones de secretos no es una garantía absoluta.
No se guardaron tokens, contraseñas, secretos persistentes ni autenticaciones
en archivos versionables. Las claves de las pruebas fueron aleatorias y efímeras.

Evidencia HTTP local: requestId `1362d430-a0c5-4516-adba-623103984f0c`,
HTTP 200, PROD-001, cantidad 3, unitPrice 19.90, totalPrice 59.70 EUR.
Coincide con el log del proveedor de esa ejecución; **no procede de Salesforce**.

La primera comprobación detectó un error de tipado en el manejador de Fastify,
corregido. Se retiró una opción obsoleta para evitar avisos. La última ejecución
de check y smoke pasó. La revisión del Apex retiró un getter no disponible de
HttpRequest y utiliza equals para coincidencias de cadenas sensibles a mayúsculas.

## Pruebas Salesforce y conectividad

| Nivel | Estado |
| --- | --- |
| Fastify por inyección | Ejecutado, 27/27 |
| HTTP real local | Ejecutado, autenticación y total correctos |
| Apex con HttpCalloutMock | Ocho métodos escritos; **no compilados ni ejecutados** |
| Named/External Credential y Permission Set | Pasos preparados; no configurados en una organización |
| Túnel HTTPS | Ejecutable local disponible; no abierto ni autorizado todavía |
| Callout real Apex → HTTPS → proveedor | **Pendiente** |
| Rechazo de autenticación desde Salesforce y restauración | Pendiente |
| LWC / modelo / instantáneas / roles ordinarios | Fuera de esta sesión; no implementados ni probados |

## Criterios y pendientes

Destino inspeccionado, contenido previo conservado, separación de proyectos,
versiones, API autenticada, pruebas locales y contrato: satisfechos.
Ausencia de secretos versionados: revisada localmente.
Organización P05 y llamada real: pendientes explícitos, no simulados.
Sin staging/commit/push ni modificaciones de otros proyectos: respetado.

Acciones personales de Alex y continuación, detalladas en [CONEXION](CONEXION.md):

1. Crear/identificar un Playground independiente de P05 y hacer login oficial.
2. Contrastar identidad y versiones API del destino; materializar las plantillas DX.
3. Alex genera e introduce el secreto local y el parámetro protegido.
4. Confirmar exposición temporal del único servicio 127.0.0.1:3055 mediante HTTPS.
5. Configurar credenciales y permisos mínimos; desplegar las dos clases y ejecutar mocks.
6. Ejecutar callout real y correlacionar requestId; si es viable, comprobar 401 y restauración.
7. Cerrar túnel y proveedor; registrar evidencia; Alex revisa y publica.

## Decisiones y límites

Node instalado conservado. TypeScript 5.9.3 fijado; versiones y motivos en
[ENVIRONMENT](ENVIRONMENT.md). Se usa ejecución TypeScript nativa y no compilados.
cloudflared se preparó como binario portable ignorado por Git, sin cambiar PATH
ni instalar servicio. Procedencia: release oficial cloudflare/cloudflared 2026.11.1;
SHA256 `341deda3db5ec498a0482254d6c38c0b7cf01a30c37bb5dd95d2216d08955e35`.

Se pospone la versión API y configuración real de credenciales hasta contar con
el destino. Los mocks no verifican compilación, red ni permisos reales.
El proveedor no implementa rate limiting propio: 429 puede proceder de infraestructura.
Los servidores deben tener reloj correcto; la sonda rechaza emisiones futuras.

## Propuesta de publicación manual de esta entrega local

Summary:
`feat: preparar proveedor de tarifas y sonda Apex de P05`

Description:

Implementa la API local autenticada del proveedor simulado con PROD-001,
contrato OpenAPI, validación, cálculo en céntimos y vigencia de 24 horas.
Prepara cliente Apex mediante Named Credential, ocho pruebas con HttpCalloutMock
y pasos de configuración/despliegue, sin LWC ni modelo de instantáneas.

Verificado: TypeScript, 27/27 pruebas locales, HTTP loopback con 200/401,
esquemas OpenAPI y auditoría de dependencias de ejecución sin avisos.
Pendiente: Playground exclusivo, versión API real, secreto de Alex,
credenciales, autorización del túnel, compilación/pruebas Apex y callout HTTPS real.
