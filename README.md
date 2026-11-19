# P05 — Consulta de tarifas de proveedor desde Salesforce

**Fase 3 completada:** producto Salesforce + cantidad → consulta HTTPS validada →
instantánea privada guardada. El histórico se lee sin contactar al proveedor,
incluso cuando la tarifa caduca.

Base publicada por Alex: `ae25cec` (fase 2).
Los cambios actuales quedan sin staging, para revisión, commit y push manuales.

## Componentes

- Proveedor Node.js/TypeScript/Fastify: tres productos ficticios; precios en céntimos.
- Cliente HTTP P05ConsultaTarifa: contrato, correlación y validación de respuesta.
- P05TarifasServicio: autorización, lectura de Product2, guardado USER_MODE e histórico propio.
- ConsultaTarifa__c privada: valores históricos, propietario y autoría estándar.
- Trigger de integridad: creación solo desde el servicio; sin edición ni borrado de instantáneas.
- Permiso funcional y conjuntos mínimos para datos, servicio y conexión.

| Producto | Precio EUR |
| --- | --- |
| PROD-001 | 19.90 |
| PROD-002 | 125.50 |
| PROD-003 | 0.99 |

Los precios se mantienen solo en [el proveedor](proveedor/src/app.ts).
Product2 no almacena precios y el cliente Apex no duplica el catálogo.
PROD-999 es un dato Salesforce separado para demostrar el 404 del proveedor.

## Resultados comprobados

- Despliegue incremental: **25 componentes**, API 68.0.
- **29/29 pruebas Apex**: 16 del cliente y 13 del servicio/integridad.
- Proveedor y contrato sin cambios; se reutiliza la evidencia de **42/42 pruebas de fase 2**.
- Consulta HTTPS real PROD-001 × 3: **59.70 EUR**, instantánea **P05-000000**.
- Producto desconocido: PRODUCT_NOT_FOUND / HTTP 404, **cero registros nuevos**.
- Lectura posterior de P05-000000 con proveedor y túnel detenidos: **cero callouts**.

Demostración real como administrador. Las pruebas automatizadas usan usuarios
mínimos y controles USER_MODE; el recorrido interactivo comercial sigue pendiente.
No hay LWC ni adaptadores @AuraEnabled y no se declara terminada la V1.

## Documentación

- [Estado y resultados](docs/STATUS.md) · [evidencia fase 3](docs/evidencias-fase-3.json).
- [Modelo](docs/MODELO.md) · [seguridad e integridad](docs/SEGURIDAD.md).
- [Despliegue, carga y demostración](docs/PERSISTENCIA.md).
- [Cliente HTTP](docs/CLIENTE_APEX.md) · [contrato OpenAPI](docs/openapi.json).
- [Alcance](docs/PROJECT_BRIEF.md) · [entorno](docs/ENVIRONMENT.md) · [conexión](docs/CONEXION.md).
- Históricos: [fase 2](docs/FASE-2.md) y [sesión 1B](docs/SESION-1B.md).

## Retomar el trabajo

La organización P05 y la clave ya existen. No recrearlas ni regenerar secretos.
Proveedor y túnel quedaron cerrados. Para leer el histórico basta Salesforce.
Cada nueva consulta satisfactoria guarda otra instantánea; no repetirla como lectura.

La [guía de persistencia](docs/PERSISTENCIA.md) separa las transacciones de carga,
consulta con insert y lectura. El manifiesto incremental está en salesforce/manifest/fase-3.xml.
Alex realiza personalmente staging, commit y push.

Para modificar el proveedor en otra fase, sus comprobaciones se ejecutan desde proveedor/:

```powershell
npm.cmd ci --ignore-scripts
npm.cmd run check
npm.cmd run smoke
```
