# P05 — Consulta de tarifas de proveedor desde Salesforce

**Fase 4 completada:** un comercial selecciona producto y cantidad en Lightning,
consulta el proveedor y guarda una instantánea privada. El histórico funciona con
proveedor y túnel detenidos. La V1 sigue pendiente de fase 5.

Base publicada por Alex: `148d0e0` (fase 3). Cambios actuales sin staging,
para revisión, commit y push manuales.

## Acceso

Iniciador de aplicaciones → **P05 Tarifas** → **Consulta de tarifas**.
Perfil mínimo y tres conjuntos P05: datos, consulta y conexión. [Guía de uso](docs/USO.md).
Demo comercial real mediante Login As autorizado, cerrado y restaurado.

## Componentes

- Proveedor Node.js/TypeScript/Fastify: tres productos ficticios; precios en céntimos.
- P05ConsultaTarifa: cliente HTTPS, contrato y correlación.
- P05TarifasServicio e integridad: autorización, USER_MODE, guardado e histórico propio.
- P05TarifasControlador y dos DTO de nivel superior: adaptador Aura sin duplicar negocio.
- p05Tarifas: LWC con SLDS, validación, confirmación, detalle, caducidad e histórico.
- Aplicación, pestaña y permisos mínimos versionados; sin secretos ni endpoint temporal.

| Producto | Precio EUR |
| --- | --- |
| PROD-001 | 19.90 |
| PROD-002 | 125.50 |
| PROD-003 | 0.99 |

La fuente de precios es [el proveedor](proveedor/src/app.ts). Product2 no almacena
precios. PROD-999 se conserva como fixture negativo, excluido del selector comercial.

## Verificación

- Despliegue incremental final: **9 componentes**, API 68.0; **36/36 Apex**.
- **21/21 Jest**, dependencias locales y lockfile. Proveedor sin cambios; 42/42 de fase 2 reutilizadas.
- Guardado comercial **P05-000001**, PROD-001 × 3, **59.70 EUR**, propietario/autoría y requestId contrastados.
- Cantidad inválida, detalle ajeno denegado y fallo sin insert ni resultado antiguo.
- Histórico/detalle tras recarga con proveedor y túnel apagados; **P05-000000** original conservado.
- Login As restaurado false; cuenta comercial conservada; puerto 3055 libre.

Reapareció el desfase temporal y se corrigió puntualmente con autorización expresa.
No se cambiaron validaciones ni fechas del proveedor. Robustez y matriz final de fallos
reales quedan para fase 5. Instalación limpia desde cero no ejecutada.

## Documentación

[Estado](docs/STATUS.md) · [evidencia fase 4](docs/evidencias-fase-4.json) · [uso/despliegue](docs/USO.md).
[Modelo](docs/MODELO.md) · [seguridad](docs/SEGURIDAD.md) · [persistencia](docs/PERSISTENCIA.md).
[Cliente HTTP](docs/CLIENTE_APEX.md) · [OpenAPI](docs/openapi.json) · [conexión](docs/CONEXION.md).
[Alcance](docs/PROJECT_BRIEF.md) · [entorno](docs/ENVIRONMENT.md).
Históricos: [fase 3](docs/FASE-3.md), [fase 2](docs/FASE-2.md), [sesión 1B](docs/SESION-1B.md).

Organización y clave ya existen. Para leer el histórico basta Salesforce.
Cada consulta nueva satisfactoria crea otra instantánea; no repetirla como lectura.
Alex realiza staging, commit y push.
