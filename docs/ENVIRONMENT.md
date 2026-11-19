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
| cloudflared | 2026.11.1 portable en .local/; SHA256 oficial verificado; túnel utilizado y cerrado en sesión 1B |
| Organización P05 | Playground exclusivo verificado; CLI autorizada; demostración como System Administrator |
| API Salesforce | 68.0 verificada en el destino y utilizada en despliegues |
| Puerto | 3055, solo 127.0.0.1; probado y liberado al finalizar |

Se conserva Node 24 LTS instalado. Fastify 5 requiere Node 20 o posterior.
TypeScript 5.9.3 se fija como compilador conocido compatible con NodeNext y
erasableSyntaxOnly; no se necesita migrar al último major para esta sonda.
Node ejecuta TypeScript con sintaxis borrable; tsc verifica sin emitir compilados.
Dependencias exactas y lockfile en proveedor/. Sin instalaciones globales.

La CLI devolvió versiones/plugins pese a avisos Get-CimInstance «Acceso denegado»
del entorno restringido. La lista de alias se procesó en memoria y solo se
mostraron alias/indicadores, sin tokens ni archivos de autenticación.
En la inspección inicial de sesión 1 solo se encontró un alias anterior; no se conectó a esa organización. En sesión 1B se autenticó el destino P05 independiente.
La primera consulta npm restringida no respondió y se canceló; la consulta e
instalación local autorizadas finalizaron correctamente.

## Fuentes de diseño

- [Fastify 5 y Node](https://fastify.dev/docs/latest/Guides/Migration-Guide-V5/)
- [LTS de Fastify](https://fastify.dev/docs/latest/Reference/LTS/)
- [Versiones de Node](https://nodejs.org/en/about/previous-releases)
- [UUID de Apex](https://developer.salesforce.com/docs/platform/apex-ref/references/apex-ref/apex-class-system-uuid.html)
- [Named Credentials actuales](https://developer.salesforce.com/docs/platform/named-credentials/guide/get-started.html)
- [API keys protegidas](https://help.salesforce.com/s/articleView?id=sf.nc_custom_headers_and_api_keys.htm&language=en_US&type=5)
- [Quick Tunnels](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/)

Las referencias respaldan el diseño. Las capacidades verificadas en el destino P05 se detallan en STATUS y en la evidencia de sesión 1B.

Binario portable descargado de la [release oficial 2026.11.1](https://github.com/cloudflare/cloudflared/releases/tag/2026.11.1). No se cambió PATH ni se instaló un servicio.

## Actualización de sesión 1B

Playwright CLI 0.1.25 preparado exclusivamente en .local/browser-tools, con caché local. Conexión a Chrome recuperada frente a la incompatibilidad del conector MCP. Sin actualizaciones globales. El Playground P05 fue creado desde Trailhead; autenticación CLI completada e identidad contrastada mediante Organization. API 68.0 confirmada por consulta autenticada.

En sesión 1B se verificó un adelanto del reloj local de unos 2,08 segundos. Con autorización expresa de Alex se ejecutó w32tm /resync /rediscover con elevación; terminó correctamente y dejó el desfase medido en pocos milisegundos, sin cambiar configuración persistente. El proveedor y el túnel se cerraron al completar la demostración.
