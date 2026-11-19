# Retomar la conexión real

Proveedor local probado; organización, credencial y túnel pendientes.
Este procedimiento está preparado, no ejecutado.

## Organización exclusiva y versión API

Alex crea o identifica un Playground nuevo de P05 en Trailhead y lo abre.
Comprueba Setup → Company Information: Organization ID y nombre; conserva
localmente dominio My Domain. No publicar IDs privados, usuario ni dominio.
No reutilizar organizaciones anteriores.

Antes del login, comprobar que `p05-tarifas-dev` sigue libre (lo estaba en la
inspección). Si está ocupado, verificar identidad; no sobrescribirlo.
Alex hace login en navegador oficial con el dominio propio del Playground:

```powershell
sf.cmd org login web --alias p05-tarifas-dev --instance-url https://DOMINIO-P05.my.salesforce.com
```

DOMINIO-P05 es un marcador. No usar --set-default. No imprimir tokens,
sf org display ni URLs reutilizables de acceso.
Contrastar Organization (Id, Name, OrganizationType, IsSandbox) con Company
Information mediante consulta dirigida a `--target-org p05-tarifas-dev`.
El alias por sí solo no acredita identidad.

Después de verificar el destino:

```powershell
sf.cmd api request rest /services/data/ --target-org p05-tarifas-dev
```

Elegir una versión devuelta por P05, mínimo 60.0 por UUID.
Desde salesforce/, sustituir VERSION_VERIFICADA por ese número:

```powershell
.\scripts\prepare-project.ps1 -ApiVersion VERSION_VERIFICADA
```

Genera sfdx-project.json y dos cls-meta.xml sin desplegar ni sobrescribir.
Estos archivos serán versionables con la versión real y sin IDs privados.
Hasta entonces no se presenta el directorio como paquete desplegable completo.

## Secreto y proveedor

Alex ejecuta `proveedor/scripts/create-local-secret.ps1` localmente.
No se ejecutó durante la implementación. Genera 32 bytes aleatorios como 64
caracteres hexadecimales en proveedor/.env, sin imprimir y sin sobrescribir.
Alex abre ese archivo localmente para introducir el valor en Salesforce;
no enviarlo por chat ni registrarlo en comandos, logs o metadatos.

Desde proveedor/: `npm.cmd start`. Comprobar `http://127.0.0.1:3055/health`.
Solo sirve la API, sin carpetas o archivos estáticos.

## Túnel: confirmación previa de Alex

Exposición propuesta: **solo el proveedor de 127.0.0.1:3055**, mediante HTTPS de
Cloudflare Quick Tunnel, durante la comprobación Salesforce de esta sesión,
cerrándolo inmediatamente después. Tarifas exige clave; /health es público y mínimo.

Antes de abrirlo, obtener confirmación expresa para esa exposición.
cloudflared 2026.11.1 ya está preparado como `.local/cloudflared.exe` dentro de
P05 (ignorado), con SHA256 oficial verificado. No se instaló globalmente ni como
servicio Windows. No es necesario modificar PATH.

Desde la raíz, con proveedor activo y exposición autorizada:

```powershell
.\.local\cloudflared.exe --version
.\.local\cloudflared.exe tunnel --url http://127.0.0.1:3055
```

Terminal de Alex en primer plano; Ctrl+C al terminar. URL temporal no versionable.
No usar autenticación por correo: no sirve para el callout no interactivo.
Quick Tunnel es desarrollo, sin disponibilidad garantizada y puede devolver 429.
Si la red lo impide, registrar error saneado. Alternativa a evaluar con autorización
separada: alojar temporalmente el mismo proveedor en un servicio HTTPS gratuito
compatible con Node 24; no contratar ni crear recursos automáticamente.

## Credenciales actuales en Salesforce

En la organización P05 verificada, Setup → Named Credentials:

| Elemento | Configuración |
| --- | --- |
| External Credential | P05_Proveedor_Externo; protocolo Custom |
| Principal | P05_Compartido; Named Principal; secuencia 1 |
| Parámetro protegido del principal | ApiKey; Alex introduce el secreto |
| Cabecera de External Credential | X-API-Key = {!$Credential.P05_Proveedor_Externo.ApiKey} |
| Named Credential actual | P05_Proveedor; URL HTTPS base del túnel; External Credential anterior |
| Opciones | Enabled for Callouts; Allow Formulas in HTTP Header; Generate Authorization Header desactivado |
| Permission Set | P05_Conexion_Proveedor; acceso al principal anterior y clase P05ConsultaTarifa |

Asignar el Permission Set solo al usuario de demostración. Comprobar requisitos
de User External Credentials de ese perfil según documentación y destino real;
no conceder permisos generales para superar errores. No es una prueba de roles
ordinarios: registrar qué tipo de usuario ejecute el callout.

Sin Legacy Named Credential, secretos en Custom Metadata ni API keys en código.
Se preparan pasos UI porque el encargo lo permite y aún no hay destino ni URL
verificados. Si después se versiona metadata, excluir secretos, URL temporal e IDs.

## Despliegue explícito y mocks

Solo con identidad y versión verificadas, desde salesforce/:

```powershell
sf.cmd project deploy start --source-dir force-app/main/default/classes --target-org p05-tarifas-dev --test-level RunSpecifiedTests --tests P05ConsultaTarifaTest --wait 10
```

Solo dos clases, sin destructivos. Ocho métodos con HttpCalloutMock preparados.
No prueban red, secreto protegido ni permisos reales. Si la operación sigue,
consultar su identificador con destino explícito. No declarar aprobado Apex
hasta compilar y ejecutar pruebas en P05.

## Callout real y cierre

Con proveedor, túnel y credencial activos, desde salesforce/:

```powershell
sf.cmd apex run --file scripts/consulta-demo.apex --target-org p05-tarifas-dev
```

Fuera de Test: HTTP 200, PROD-001, cantidad 3, EUR, unitario 19.90, total 59.70,
UUID y vigencia correctos. Correlacionar requestId del resultado Apex con el log
del proveedor. Retener solo resultado saneado, no el debug log completo.
HTTP local o curl al túnel no acreditan este recorrido.

Si es viable, Alex introduce temporalmente un valor incorrecto en el parámetro
protegido; repetir y verificar UNAUTHORIZED/401 correlacionado. Alex restaura
el valor válido y se comprueba de nuevo éxito. No dejar permisos temporales.
Nunca imprimir cabeceras, secretos ni cuerpos de errores externos.

Detener proveedor y túnel. Registrar en STATUS resultados saneados y tipo de
usuario, separando mocks de llamada real. Los secretos los gestiona Alex.
