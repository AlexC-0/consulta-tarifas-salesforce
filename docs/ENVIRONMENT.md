# Entorno comprobado — 19/11/2026

| Elemento | Resultado |
| --- | --- |
| Sistema | Windows; PowerShell |
| Node.js | 24.13.0 |
| npm | 11.6.2 |
| Git | 2.56.1.windows.1 |
| Salesforce CLI | 2.158.7, win32-x64, Node 24.13.0 |
| Plugins CLI relevantes | apex 4.4.7; api 2.0.28; auth 6.0.5; org 7.0.13; deploy-retrieve 4.3.2 |
| Fastify | 5.12.8 |
| TypeScript | 5.9.3 |
| @types/node | 24.19.2 |
| cloudflared | 2026.11.1 portable en .local/; SHA256 oficial verificado; túneles de fase 1B y fases 2–3 utilizados y cerrados |
| Organización P05 | Playground exclusivo verificado; CLI autorizada; demostración como System Administrator |
| API Salesforce | 68.0 verificada en el destino y utilizada en despliegues |
| Puerto | 3055, solo 127.0.0.1; probado y liberado al finalizar |

Se conserva Node 24 LTS instalado. Fastify 5 requiere Node 20 o posterior.
TypeScript 5.9.3 se fija como compilador conocido compatible con NodeNext y
erasableSyntaxOnly; no se necesita migrar al último major para esta sonda.
Node ejecuta TypeScript con sintaxis borrable; tsc verifica sin emitir compilados.
Dependencias exactas y lockfile en proveedor/. Sin instalaciones globales.

La CLI devolvió versiones/plugins pese a avisos Get-CimInstance «Acceso denegado»
del entorno restringido. Las comprobaciones de identidad omitieron tokens y
archivos de autenticación. El destino P05 dispone de autenticación independiente.

## Fuentes de diseño

- [Fastify 5 y Node](https://fastify.dev/docs/latest/Guides/Migration-Guide-V5/)
- [LTS de Fastify](https://fastify.dev/docs/latest/Reference/LTS/)
- [Versiones de Node](https://nodejs.org/en/about/previous-releases)
- [UUID de Apex](https://developer.salesforce.com/docs/platform/apex-ref/references/apex-ref/apex-class-system-uuid.html)
- [Named Credentials actuales](https://developer.salesforce.com/docs/platform/named-credentials/guide/get-started.html)
- [API keys protegidas](https://help.salesforce.com/s/articleView?id=sf.nc_custom_headers_and_api_keys.htm&language=en_US&type=5)
- [Quick Tunnels](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/)

Las referencias respaldan el diseño. Las capacidades verificadas en el destino P05 se detallan en STATUS y en la evidencia de fase 1B.

Binario portable descargado de la [release oficial 2026.11.1](https://github.com/cloudflare/cloudflared/releases/tag/2026.11.1). No se cambió PATH ni se instaló un servicio.

## Actualización de fase 1B

Las comprobaciones de navegador utilizaron Playwright CLI 0.1.25 en .local/browser-tools,
con caché local y sin actualizaciones globales. El Playground P05 fue creado desde
Trailhead; autenticación CLI completada e identidad contrastada mediante Organization.
API 68.0 confirmada por consulta autenticada.

En fase 1B se verificó un adelanto del reloj local de unos 2,08 segundos.
La sincronización puntual mediante w32tm /resync /rediscover con elevación terminó
correctamente y dejó el desfase medido en pocos milisegundos, sin cambiar configuración
persistente. El proveedor y el túnel se cerraron al completar la demostración.

## Actualización de fase 2

Versiones de ejecución y API 68.0 conservadas. Ajv 8.20.0, que ya estaba en el
lockfile como dependencia transitiva, se declara también como dependencia directa
de desarrollo para ejecutar las pruebas del contrato. Sin actualización global.

Identidad de Organization P05 y perfil System Administrator comprobados de nuevo.
Dos clases desplegadas, 16/16 pruebas Apex, 42/42 pruebas del proveedor y TypeScript
correcto. Cuatro llamadas reales correlacionadas. Solo se actualizó la URL de la
Named Credential, sin cambios en claves ni permisos. No se modificó el reloj.
Proveedor y túnel cerrados, puerto 3055 libre. Evidencia en STATUS.
## Actualización de fase 3

API 68.0 y herramientas conservadas. Despliegue incremental de 25 componentes;
29/29 Apex (16 cliente y 13 servicio). Proveedor y OpenAPI no cambiaron; no se
repitieron sus 42 pruebas. Conversión DX local correcta.

Product2.Name admite 255 caracteres. Salesforce rechaza Restrict en lookups hijos
a Product2; se desplegó SetNull, sin cascada, con copias históricas independientes.
Los DateTime guardados se leen con resolución de segundos, comprobada en pruebas
y en la evidencia real.

Nuevo desfase pequeño diagnosticado: emisión 42 ms futura respecto a Salesforce.
Windows aceptó w32tm /resync /rediscover pero mantenía aproximadamente 91 ms de
adelanto. Con la sincronización puntual autorizada se completó el ajuste desde
la misma fuente NTP mediante Set-Date. Medición posterior: +13.05225 ms (reloj
local por detrás). Sin configuración persistente modificada ni validaciones relajadas.

Una instantánea real conservada (referencia saneada P05-000000), lectura posterior
sin proveedor/túnel y cero callouts. Puerto 3055 libre al cierre. Perfil real
System Administrator; permisos de usuarios mínimos comprobados en tests.
## Actualización de fase 4

@salesforce/sfdx-lwc-jest 7.9.0 (dist-tag summer26), Jest 29.7.0 y LWC 8.28.2,
dependencias locales con lockfile. 21/21 Jest; API 68.0, nueve componentes incrementales
y 36/36 Apex. .forceignore excluye pruebas/dependencias del metadata desplegado.

Cuenta comercial real autorizada con Minimum Access - Salesforce, sin rol y tres
conjuntos P05; LightningExperienceUser y lectura UserExternalCredential específicos.
Login As restaurado false. Se conserva la instantánea comercial y la administrativa.
Proveedor/túnel cerrados, puerto 3055 libre. Desfase diagnosticado: emisión 13 ms futura.
Sincronización puntual autorizada; w32tm correcto y ajuste NTP con time.windows.com,
offset posterior +6.01825 ms. Sin configuración persistente ni validación modificadas.
Resultados y límites en [STATUS](STATUS.md), [evidencia fase 4](evidencias-fase-4.json).

## Fase 5

Mismas herramientas y API 68.0, sin instalación o actualización global. Despliegue
incremental de ocho componentes; 40/40 Apex, 30/30 Jest, 43/43 pruebas del proveedor
y TypeScript correcto. La prueba adicional usa HTTP loopback real y espera diez
segundos para el timeout; las otras 42 cubren inyección y contrato.

La CLI Playwright local 0.1.25 conecta con la extensión existente. El conector MCP
no conectó por incompatibilidad de protocolo; no se actualizó. Los artefactos de
navegador se mantienen fuera de control de versiones. Sin cambios de reloj o NTP.
La verificación externa y restauración se detallan en [STATUS](STATUS.md).
