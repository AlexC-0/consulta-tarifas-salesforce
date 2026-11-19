# P05 — Consulta de tarifas de proveedor desde Salesforce

**Sesión 1B completada:** llamada real desde Apex mediante Named Credential y
HTTPS al proveedor autenticado, rechazo de clave incorrecta y restauración comprobados.
La demostración utilizó un administrador; los permisos del futuro comercial no
están acreditados. No hay todavía LWC ni modelo de instantáneas.

La base local fue publicada por Alex en `603ebd1`. Los cambios de sesión 1B quedan
para su revisión, staging, commit y push manuales.

## Componentes

- `proveedor/`: Node.js 24, TypeScript y Fastify 5; PROD-001 a 19.90 EUR.
- `salesforce/`: proyecto DX API 68.0, sonda Apex, ocho métodos de prueba,
  External Credential y Permission Set mínimo.
- `salesforce/templates/`: Named Credential actual sin URL temporal ni secreto.
- `docs/`: [alcance](docs/PROJECT_BRIEF.md), [resultados](docs/STATUS.md),
  [entorno](docs/ENVIRONMENT.md), [OpenAPI](docs/openapi.json),
  [conexión reproducible](docs/CONEXION.md) y [evidencia saneada](docs/evidencias-sesion-1b.json).

## Pruebas locales

Desde `proveedor/`:

```powershell
npm.cmd ci --ignore-scripts
npm.cmd run check
npm.cmd run smoke
```

`check` verifica tipos y ejecuta 27 pruebas. `smoke` abre temporalmente
`127.0.0.1:3055`, prueba HTTP con clave efímera y cierra el servicio.
Estas pruebas no sustituyen el callout real de Salesforce.

## Retomar el proveedor

Ya existe una clave local en `proveedor/.env`, excluida de Git. No regenerarla.
Desde `proveedor/`:

```powershell
npm.cmd start
```

Para una instalación nueva sin .env, Alex ejecuta primero
`scripts/create-local-secret.ps1`; no imprime el valor ni sobrescribe archivos.
La sesión 1B contó con autorización expresa de Alex para que Codex generara y
cargara el secreto mediante un proceso local.

El proveedor escucha solo en loopback. No abre túneles automáticamente.
/health es mínimo y público; tarifas exige clave y UUID.
**Proveedor y túnel de la demostración quedaron cerrados.** Para repetirla,
seguir CONEXION: la URL del Quick Tunnel cambia y debe actualizarse en Salesforce.
Mantener sincronizado el reloj: Apex rechaza emisiones futuras y tarifas caducadas.
