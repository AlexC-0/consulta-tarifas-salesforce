# Instalación y reproducción de V1

Procedimiento revisado estáticamente el 19/11/2026 sobre fase 5B publicada en
`756e931`. **No ejecutado en fase 6; no acredita instalación limpia.** La instalación
incremental existente sí tiene evidencia de fases 3–5. Decisión de alcance en
[ACEPTACION-V1](ACEPTACION-V1.md#instalacion).

## Condiciones previas

- Usar exclusivamente el destino P05 autorizado. Creación, identificación inicial,
  login e introducción del secreto son manuales; esta guía no autoriza otra organización.
- En la organización actual, conservar las cinco instantáneas, la cuenta comercial,
  productos, credenciales y permisos. No aplicar una reinstalación como reinicialización.
- Herramientas existentes según [ENVIRONMENT](ENVIRONMENT.md): Node 24.13.0,
  npm 11.6.2 y Salesforce CLI 2.158.7; API 68.0. Lockfiles en ambas carpetas.
  No actualizar herramientas globales para seguir la guía.
- El procedimiento limpio presupone un P05 vacío autorizado en un alcance posterior,
  con licencia Salesforce y perfil **Minimum Access - Salesforce** disponible con ese
  nombre: las suites de servicio/controlador lo consultan literalmente. No se prueba
  compatibilidad universal con otras ediciones, licencias o perfiles traducidos.
- Desde `salesforce/`, comprobar identidad sin mostrar autenticaciones:

```powershell
sf.cmd data query --query "SELECT Name,OrganizationType,IsSandbox FROM Organization" --target-org p05-tarifas-dev
sf.cmd api request rest /services/data/ --target-org p05-tarifas-dev
```

Contrastar los datos con el P05 identificado manualmente y confirmar API 68.0 antes
de escribir. El alias no acredita por sí solo identidad. No usar destino implícito,
salidas de autenticación ni URLs reutilizables de acceso.

## Dependencias y proveedor

Desde la raíz del repositorio, preparar únicamente dependencias locales:

```powershell
Push-Location proveedor
npm.cmd ci --ignore-scripts
Pop-Location
Push-Location salesforce
npm.cmd ci --ignore-scripts
Pop-Location
```

Comprobar el código de salida de cada comando antes de continuar. El proyecto DX
y metadata ya están versionados con API 68.0; **no ejecutar prepare-project.ps1**
en este checkout. Es una herramienta histórica que no sobrescribe archivos y solo
preparaba dos clases iniciales, no una instalación V1 completa.

En el P05 actual reutilizar `proveedor/.env`. Solo para una primera configuración
sin ese archivo, ejecutar manualmente desde `proveedor/`:

```powershell
.\scripts\create-local-secret.ps1
```

El script no sobrescribe ni imprime la clave. No copiarla a argumentos, commits,
capturas o logs. El parámetro protegido se introducirá manualmente en Salesforce;
`.env.example` es un formato vacío, no una credencial utilizable.

Pruebas locales reproducibles, desde la raíz (no ejecutadas en fase 6):

```powershell
Push-Location proveedor
npm.cmd run check
Pop-Location
Push-Location salesforce
npm.cmd run test:unit
Pop-Location
```

`check` incluye TypeScript y los tests actuales, incluida la instrumentación 5B.
No etiquetar una ejecución futura como los 43 tests de fase 5: esa suite histórica
precede a los dos tests nuevos de 5B. Jest tiene evidencia histórica 30/30 en fase 5.

Para la demostración autorizada, desde `proveedor/` ejecutar `npm.cmd start` en una
terminal dedicada: solo `127.0.0.1:3055`, API key obligatoria y sin banco de fallos.
Preparar el túnel según [CONEXION](CONEXION.md), con autorización nueva de servicio,
puerto, duración y finalidad. El binario portable y la URL temporal son locales y
no forman parte del checkout; no asumir que `.local/cloudflared.exe` existe en
otra máquina. Su preparación/verificación manual queda fuera de esta revisión.

## Orden para una primera instalación completa

No desplegar todas las clases antes de los objetos. No reproducir los manifiestos
históricos fase-3/fase-4/fase-5 como una cadena limpia sobre las fuentes actuales:
los permisos y clases evolucionaron y ahora contienen referencias a la interfaz.

Desde `salesforce/`, únicamente en una instalación limpia autorizada:

**1. Cliente independiente y su prueba**, sin dependencias de los objetos P05:

```powershell
sf.cmd project deploy start --source-dir force-app/main/default/classes/P05ConsultaTarifa.cls --source-dir force-app/main/default/classes/P05ConsultaTarifaTest.cls --target-org p05-tarifas-dev --test-level RunSpecifiedTests --tests P05ConsultaTarifaTest --wait 10
```

**2. Paquete de conexión sin secreto.** External Credential y su principal son
dependencia de P05_Conexion_Proveedor; ese Permission Set referencia al cliente
del paso 1. La Named Credential incorpora el endpoint HTTPS autorizado:

```powershell
$p05Endpoint = Read-Host 'Endpoint HTTPS temporal autorizado de P05'
.\scripts\prepare-connection.ps1 -Endpoint $p05Endpoint
sf.cmd project deploy start --metadata-dir ..\.local/connection-metadata --target-org p05-tarifas-dev --wait 10
```

El script solo admite HTTPS de Quick Tunnel y genera tres componentes en `.local`.
Si el directorio ya existe, detenerse y revisar su procedencia; no borrar `.local`
ni sobrescribir credenciales. En una instalación existente actualizar solo el endpoint.

**3. Conjunto completo de fuentes V1**, con esquema, servicio, trigger, pruebas,
DTO, interfaz, aplicación/pestaña, permisos y definición de External Credential:

```powershell
sf.cmd project deploy start --manifest manifest/v1.xml --target-org p05-tarifas-dev --test-level RunSpecifiedTests --tests P05ConsultaTarifaTest --tests P05TarifasServicioTest --tests P05TarifasControladorTest --wait 10
```

[v1.xml](../salesforce/manifest/v1.xml) enumera todos los componentes de `force-app`.
CustomObject ConsultaTarifa__c incluye sus 14 campos; Product2 aporta campo y regla.
El Permission Set funcional necesita controlador, aplicación, pestaña y permiso
personalizado; se despliegan juntos. Las suites necesitan los tres Permission Sets.
La definición de conexión también figura aquí para conservar un inventario completo;
la Named Credential dinámica procede del paso 2 y el secreto no está en metadata.
Introducir el secreto después de estos despliegues, no antes de recrear definiciones.

Tras **cada** despliegue exigir resultado final satisfactorio. Si sigue en curso,
consultar el identificador devuelto, sin volver a enviar el despliegue:

```powershell
$p05DeployId = Read-Host 'Identificador del despliegue pendiente de P05'
sf.cmd project deploy report --job-id $p05DeployId --target-org p05-tarifas-dev --wait 10
```

Estos comandos son un procedimiento revisado, no resultados de despliegue de fase 6.
`.forceignore` excluye dependencias y Jest del paquete; no eliminar los tests Apex.

**4. Configuración manual y permisos mínimos.** Introducir ApiKey protegida en
P05_Compartido mediante Setup, siguiendo [CONEXION](CONEXION.md). Asignar por Setup
los tres conjuntos P05 a la cuenta comercial autorizada, con perfil mínimo y sin
rol. Ver [SEGURIDAD](SEGURIDAD.md). No asignar al administrador y presentar eso
como prueba comercial. El administrador de diagnóstico necesita también el permiso
funcional y de conexión para las sondas que invoquen el servicio.

**5. Catálogo ficticio**, en transacción administrativa independiente del callout:

```powershell
sf.cmd apex run --file scripts/cargar-productos.apex --target-org p05-tarifas-dev
```

Reutiliza coincidencias válidas y se detiene ante incompatibilidades. No cambia
precios en Product2. `cargar-producto-negativo.apex` es opcional para la sonda 404;
PROD-999 no debe aparecer en el selector. No cargarlo como cuarto producto comercial.

## Instalación incremental existente

La fase 5 ya desplegó ocho componentes sobre las fases previas. Su comando y
precondición de fase 4 constan en [USO](USO.md). La fase 5B añadió herramientas y
diagnóstico; la fase 6 añade documentación y manifiesto, **sin despliegue necesario**.
No volver a desplegar conexión, permisos ni código como parte de esta revisión.

## Demostración funcional y lectura sin proveedor

Con proveedor/túnel autorizados, endpoint actual y clave configurada:

1. Sonda administrativa opcional, desde `salesforce/`:
   `sf.cmd apex run --file scripts/consulta-demo.apex --target-org p05-tarifas-dev`.
   Esperado: PROD-001 × 3, EUR, 19.90/59.70, UUID y duración exacta de 24 h; sin DML.
   Conservar solo el JSON emitido y correlación, no la salida completa de depuración.
2. En la sesión comercial autorizada abrir P05 Tarifas → Consulta de tarifas.
   Seguir [USO](USO.md): cantidad inválida sin envío, consulta válida, confirmación,
   detalle e histórico propio. Cada éxito crea una instantánea que se conserva.
   Login As, si se requiere, necesita autorización propia; no es requisito de la
   aplicación ni está autorizado por esta guía.
3. Cerrar solo procesos propios, restaurar el endpoint inicial si se sustituyó y
   comprobar puerto 3055 libre. Recargar, actualizar histórico y abrir el detalle
   desde la sesión comercial. Deben seguir disponibles; no pulsar guardar como lectura.
4. Comprobación administrativa complementaria: desde `salesforce/`,
   `sf.cmd apex run --file scripts/lectura-historico.apex --target-org p05-tarifas-dev`.
   Necesita una instantánea del propio ejecutor; no lee la del comercial. La sonda
   exige cero callouts. `consulta-guardar.apex` crea otra fila y no sustituye esta lectura.

No alterar relojes para una demostración. Los errores temporales se investigan
sin desplazar fechas ni relajar validaciones. La matriz completa de fallos ya está
en las evidencias de fase 5; el diagnóstico 5B se conserva y no se repite en fase 6.
