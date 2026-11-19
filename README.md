# P05 — Consulta de tarifas de proveedor desde Salesforce

**Fase 2 completada:** catálogo de tres productos y cliente Apex parametrizable,
con pruebas aisladas y cuatro llamadas HTTPS reales correlacionadas.
Demostración como administrador; permisos comerciales todavía no acreditados.
Product2, persistencia, instantáneas y LWC quedan para fases posteriores.

Base publicada por Alex: `679182b` (sesión 1B).
Cambios de fase 2 sin staging, para revisión, commit y push manuales de Alex.

## Catálogo ficticio

| Código | Precio unitario EUR |
| --- | --- |
| PROD-001 | 19.90 |
| PROD-002 | 125.50 |
| PROD-003 | 0.99 |

La fuente de precios de ejecución es el catálogo en
[app.ts](proveedor/src/app.ts), en céntimos enteros. Apex no incorpora esos precios.
Cantidad entera entre 1 y 10.000, vigencia de 24 horas, sin impuestos ni descuentos.

## Componentes y documentación

- `proveedor/`: Node.js 24, TypeScript y Fastify 5; API autenticada sin base de datos.
- `salesforce/`: API 68.0; cliente interno, pruebas y credenciales sin secretos.
- [Cliente Apex](docs/CLIENTE_APEX.md): entradas, validaciones y errores.
- [Alcance](docs/PROJECT_BRIEF.md), [estado](docs/STATUS.md), [entorno](docs/ENVIRONMENT.md).
- [OpenAPI y ejemplos](docs/openapi.json), [conexión](docs/CONEXION.md).
- [Evidencia fase 2](docs/evidencias-fase-2.json).
- [Histórico sesión 1B](docs/SESION-1B.md) y [evidencia 200/401/200](docs/evidencias-sesion-1b.json).

## Comprobaciones

Desde `proveedor/`:

```powershell
npm.cmd ci --ignore-scripts
npm.cmd run check
npm.cmd run smoke
```

`check` verifica tipos y ejecuta **42 pruebas**, incluidas validaciones OpenAPI.
`smoke` abre solo 127.0.0.1:3055 con clave efímera y prueba los tres productos,
404, health y autenticación; cierra el servicio al terminar.
En P05 se desplegaron dos clases y pasaron **16 pruebas Apex con mocks**.
La evidencia HTTPS real es independiente de esos resultados.

## Retomar una demostración

La organización P05 y su secreto ya existen. No recrearlos ni regenerar la clave.
Desde `proveedor/`, `npm.cmd start` usa el .env local ignorado y escucha solo en loopback.
No abre túneles automáticamente. /health es público y mínimo; tarifas exige clave y UUID.

**Proveedor y túnel de fase 2 quedaron cerrados.** Seguir [CONEXION](docs/CONEXION.md)
para otra demostración: la URL temporal debe actualizarse y la exposición requiere
autorización aplicable. Mantener el reloj sincronizado: Apex rechaza fechas futuras
y caducadas; fase 2 no requirió modificar la hora.
