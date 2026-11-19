# P05 — Consulta de tarifas de proveedor desde Salesforce

Proyecto independiente con datos ficticios. Sesión 1: API local autenticada y
sonda Apex preparada. **La conexión real desde Salesforce está pendiente.**
No existe todavía LWC ni guardado de instantáneas.

## Estructura

- `proveedor/`: Node.js 24, TypeScript y Fastify 5; catálogo en código.
- `salesforce/`: cliente Apex fijo para PROD-001 × 3, mocks y preparación DX.
- `docs/`: [alcance](docs/PROJECT_BRIEF.md), [estado y evidencias](docs/STATUS.md),
  [entorno](docs/ENVIRONMENT.md), [contrato OpenAPI](docs/openapi.json) y
  [conexión paso a paso](docs/CONEXION.md).

## Comprobación local

Desde `proveedor/`, con las versiones registradas en ENVIRONMENT:

```powershell
npm.cmd ci --ignore-scripts
npm.cmd run check
npm.cmd run smoke
```

`check` ejecuta TypeScript y pruebas por inyección. `smoke` abre temporalmente
solo `127.0.0.1:3055`, comprueba HTTP con un secreto efímero en memoria y cierra
el servicio. No usa Salesforce, HTTPS ni el secreto de desarrollo de Alex.

## Arranque para la conexión

Alex ejecuta una vez desde `proveedor/`:

```powershell
.\scripts\create-local-secret.ps1
npm.cmd start
```

El script crea `.env` ignorado por Git, no imprime el secreto y no sobrescribe
un archivo existente. Alex introduce ese mismo valor en el parámetro protegido
de Salesforce según CONEXION. No pegarlo en chats, comandos ni documentación.

El servidor escucha exclusivamente en `127.0.0.1:3055`. `GET /health` devuelve
solo estado. `POST /v1/tarifas/consultar` exige clave y UUID. Sin secreto válido
el arranque falla. Ctrl+C detiene el servicio. No se abre un túnel automáticamente.

Alex revisa, hace staging, commit y push por sesión. Convención:
`tipo: descripción en castellano`; descripción basada en resultados ejecutados.
