# Conexión P05 — configuración verificada y repetición

La fase 3 añade guardado real e histórico sin callouts; véase [PERSISTENCIA](PERSISTENCIA.md). La fase 2 conserva las tres tarifas 200 y el 404; la sesión 1B conserva 200 → 401 → 200.
Resultados en [STATUS](STATUS.md); evidencia en [evidencias-sesion-1b.json](evidencias-sesion-1b.json).
Proveedor y túnel quedaron cerrados. No crear otro Playground ni regenerar la clave.

## Destino y herramientas

El Playground P05 Consulta Tarifas ya existe y está autenticado en la CLI como
p05-tarifas-dev. Se contrastó Organization con la tarjeta de Trailhead y se comprobó
API 68.0. Antes de nuevas escrituras, verificar que el alias sigue apuntando al
destino autorizado; no usar destinos implícitos ni sf org display.

La creación y el login originales están completados. Para una instalación nueva,
crear una organización independiente; Alex realiza login personal en navegador
oficial, sin --set-default. Consultar versiones con:

```powershell
sf.cmd api request rest /services/data/ --target-org p05-tarifas-dev
```

El proyecto actual ya contiene sfdx-project.json y cls-meta.xml con 68.0.
El script prepare-project.ps1 se conserva para instalaciones nuevas; no ejecutarlo
sobre los archivos existentes, porque se niega a sobrescribirlos.

## Proveedor y secreto

Desde proveedor/:

```powershell
npm.cmd ci --ignore-scripts
npm.cmd start
```

Usa el .env ya existente. El proceso solo escucha en 127.0.0.1:3055.
GET /health devuelve estado mínimo; tarifas exige X-API-Key y X-Request-Id.
No se sirven carpetas. Sin secreto válido, el arranque falla.

Para una instalación nueva sin .env, usar scripts/create-local-secret.ps1.
No sobrescribe ni imprime el valor. La autorización de sesión 1B permitió a Codex
ejecutarlo y cargar la clave mediante un helper local; no concede una autorización
general para mostrar secretos o cambiar credenciales ajenas.

## Reloj

Mantener el reloj del equipo sincronizado. La validación de Apex rechaza fechas
futuras y caducadas. En sesión 1B se diagnosticaron 2,08 s de adelanto y se ejecutó,
con autorización expresa y elevación de Windows, una resincronización puntual.
No añadir tolerancias arbitrarias ni alterar fechas del proveedor para superar pruebas.

## Túnel temporal

Las autorizaciones de sesiones anteriores cubrieron sus demostraciones ya cerradas. Antes de una nueva
exposición, confirmar autorización para el mismo entorno y finalidad.

Desde la raíz del repositorio, con proveedor activo:

```powershell
.\.local\cloudflared.exe --no-autoupdate tunnel --url http://127.0.0.1:3055
```

cloudflared portable 2026.11.1 está preparado en .local, con checksum verificado.
No instalar servicios globales. Exponer solo ese puerto durante la comprobación;
tarifas tiene API key y /health es público. Cerrar al terminar.
La URL HTTPS cambia al iniciar otro Quick Tunnel; no versionarla.
No añadir autenticación por correo, incompatible con el callout no interactivo.

## Metadata reproducible sin secretos

Configuración comprobada:

| Elemento | Valor |
| --- | --- |
| External Credential | P05_Proveedor_Externo; Custom |
| Principal | P05_Compartido; NamedPrincipal; secuencia 1 |
| Parámetro protegido | ApiKey; encrypted=true |
| Cabecera | X-API-Key = {!$Credential.P05_Proveedor_Externo.ApiKey}; secuencia 1 |
| Named Credential | P05_Proveedor; SecuredEndpoint; callouts habilitados |
| Opciones | Merge fields en cabecera activado; Authorization automática desactivada |
| Permission Set | P05_Conexion_Proveedor; solo principal y clase P05ConsultaTarifa |

External Credential y Permission Set están en force-app.
Named Credential es una plantilla sin endpoint temporal, dentro de templates/.
prepare-connection.ps1 genera un paquete Metadata API de tres componentes sin
secreto bajo .local/connection-metadata. No sobrescribe un staging existente.
Antes de repetir, retirar o archivar únicamente ese directorio temporal generado,
conservando .env y los originales. Nunca borrar .local completo.

Para una primera instalación, desde salesforce/, ejecutar en este orden: clases,
paquete de conexión y asignación al usuario de la demostración.

```powershell
sf.cmd project deploy start --source-dir force-app/main/default/classes --target-org p05-tarifas-dev --test-level RunSpecifiedTests --tests P05ConsultaTarifaTest --wait 10
.\scripts\prepare-connection.ps1 -Endpoint https://URL-TEMPORAL.trycloudflare.com
sf.cmd project deploy start --metadata-dir ..\.local\connection-metadata --target-org p05-tarifas-dev --wait 10
sf.cmd org assign permset --name P05_Conexion_Proveedor --target-org p05-tarifas-dev
```

Comprobar el resultado satisfactorio de cada paso antes de continuar. La URL del
ejemplo es un marcador: sustituirla por la real. No desplegarlo literalmente.
Para una repetición con credenciales ya configuradas, actualizar solo la URL de
P05_Proveedor mediante Setup y conservar principal, clave y permisos.
No recrearlos por rutina ni asignar permisos a usuarios ajenos a la demostración.
Si una operación continúa asíncronamente, consultar su resultado final con destino
explícito; ejecutar un comando no acredita éxito.

## Parámetro protegido

El valor de ApiKey está configurado. No debe recuperarse ni imprimirse para verificarlo.
Su funcionamiento se comprueba con la llamada real.

Para una instalación nueva, introducirlo en el principal mediante Setup o,
si Alex lo autoriza expresamente, mediante la API oficial:
POST /services/data/v68.0/named-credentials/credential, con protocolo Custom,
principal P05_Compartido, tipo NamedPrincipal y credentials.ApiKey.encrypted=true.
PUT sobre el mismo recurso permite sustituir/restaurar el valor.
El secreto viaja por stdin desde .env, nunca como argumento, código Apex o metadata.
No conservar cuerpos de respuesta ni logs de depuración completos.

## Demostración real

Desde salesforce/, con proveedor y túnel activos y URL actualizada:

```powershell
sf.cmd apex run --file scripts/consulta-demo.apex --target-org p05-tarifas-dev
```

Esperado: HTTP 200, PROD-001, cantidad 3, EUR, 19.90, 59.70, UUID y 24 horas.
Guardar únicamente los campos que emite el script y correlacionar requestId con
el log mínimo del proveedor. No copiar la salida completa de depuración.

La prueba negativa sustituye temporalmente el parámetro protegido por otra clave,
ejecuta la sonda y exige UNAUTHORIZED en Apex y 401 en proveedor con el mismo UUID.
Restaurar siempre la clave válida, incluso si falla la comprobación, y exigir un
nuevo éxito correlacionado. No dejar configuración inválida.

Estas llamadas se ejecutan fuera de Test. Los 16 métodos HttpCalloutMock actuales
no prueban red o permisos ordinarios. La demostración 1B se realizó como
System Administrator; no se atribuye a un comercial.

Detener los procesos propios de proveedor y túnel, verificar puerto libre y
registrar resultados saneados. No modificar procesos o configuraciones ajenos.

## Repetición del catálogo de fase 2

Con la organización existente, la clave conservada y un túnel autorizado activo,
actualizar únicamente la URL de P05_Proveedor. No recrear External Credential,
principal, parámetro protegido o permisos. En fase 2 se materializó la plantilla
Named Credential bajo .local y se desplegó un paquete de un solo componente:
únicamente cambió su URL. No versionar el endpoint temporal.

Desde salesforce/:

```powershell
sf.cmd apex run --file scripts/consulta-catalogo.apex --target-org p05-tarifas-dev
```

Esperado: PROD-001 × 3 = 59.70, PROD-002 × 2 = 251.00, PROD-003 × 7 = 6.93 EUR;
PROD-999 × 1 produce PRODUCT_NOT_FOUND y HTTP 404 en el proveedor.
El script comprueba importes, rechazo del desconocido y cero DML; emite únicamente
campos de tarifa o categoría/requestId, sin cuerpo externo. Correlacionar los cuatro
UUID con los logs mínimos y conservar solo esa evidencia saneada.
La prueba de clave incorrecta de sesión 1B no se repite por rutina si no cambia
la autenticación ni hay indicios de fallo. Cerrar los procesos propios al terminar.
## Estado tras fase 3

Conexión y clave existentes reutilizadas. Se actualizó solo la URL temporal para
la demostración autorizada; proveedor y túnel cerrados después. La instantánea
P05-000000 permanece legible sin esos procesos. No volver a crear conexión o
secretos para leerla. La siguiente exposición temporal requiere autorización aplicable.

Los scripts antiguos consulta-demo.apex y consulta-catalogo.apex consultan sin
guardar. Para el servicio de persistencia, usar las transacciones separadas de
[PERSISTENCIA](PERSISTENCIA.md). Los resultados actuales están en
[evidencias-fase-3.json](evidencias-fase-3.json).