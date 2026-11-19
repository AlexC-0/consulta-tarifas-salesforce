# P05 — Consulta de tarifas de proveedor desde Salesforce

Fase 5: robustez temporal, vigencia estimada desde Salesforce y matriz de fallos.
Un comercial selecciona producto y cantidad, consulta el proveedor y guarda una
instantánea privada. El histórico funciona sin proveedor. **V1 no cerrada**:
quedan por aislar entregas repetidas ante 429/503 en el recorrido externo.

Base publicada: fase 4 en `df23ec6`, revisión documental en `bece641`.
Los cambios de fase 5 quedan preparados para revisión, sin commit ni publicación.

## Acceso y componentes

Iniciador de aplicaciones → **P05 Tarifas** → **Consulta de tarifas**.
Perfil mínimo y tres conjuntos P05: datos, consulta y conexión. [Guía de uso](docs/USO.md).

- Proveedor Node.js/TypeScript/Fastify, autenticado, catálogo ficticio e importes en céntimos.
- Cliente Apex: contrato estricto, correlación y timeout de diez segundos, sin reintentos.
- Servicio e integridad: autorización, USER_MODE, instantáneas privadas e inmutables.
- Controlador y DTO: operaciones comerciales y referencia temporal de Salesforce.
- LWC con SLDS: validación, confirmación, detalle, vigencia estimada e histórico propio.
- Banco de fallos aislado y desactivado en el arranque normal; sin controles comerciales.

| Producto | Precio EUR |
| --- | --- |
| PROD-001 | 19.90 |
| PROD-002 | 125.50 |
| PROD-003 | 0.99 |

La fuente de precios es [el proveedor](proveedor/src/app.ts). Product2 no almacena
precios. PROD-999 es un fixture negativo excluido del selector comercial.

## Robustez temporal y verificación

Emisión futura admitida hasta **1000 ms**, duración exacta de **24 horas** y
**ninguna tolerancia de caducidad**. Recepción única al retornar Http.send y nueva
comprobación de vigencia al guardar. No se cambian relojes ni fechas recibidas.

El LWC usa hora de Salesforce y tiempo monotónico; actualiza la referencia al
reanudar la vista. La latencia puede dejar la vigencia pendiente de verificar.
No hay sondeo al proveedor ni renovación de instantáneas.

Despliegue incremental de ocho componentes y **40/40 Apex**. **30/30 Jest**,
**43/43 pruebas del proveedor**, incluida matriz HTTP local real, y TypeScript correcto.
Resultados externos, conservación de datos, restauración y límites en [STATUS](docs/STATUS.md).
Instalación limpia desde cero no ejecutada.

## Documentación

[Estado y matriz](docs/STATUS.md) · [fase 5](docs/FASE-5.md) · [uso/despliegue](docs/USO.md).
[Modelo](docs/MODELO.md) · [seguridad](docs/SEGURIDAD.md) · [persistencia](docs/PERSISTENCIA.md).
[Cliente HTTP](docs/CLIENTE_APEX.md) · [OpenAPI](docs/openapi.json) · [conexión](docs/CONEXION.md).
[Alcance](docs/PROJECT_BRIEF.md) · [entorno](docs/ENVIRONMENT.md).
Históricos: [fase 4](docs/FASE-4.md), [fase 3](docs/FASE-3.md), [fase 2](docs/FASE-2.md), [fase 1B](docs/FASE-1B.md).

Organización y clave ya existen. Leer el histórico solo requiere Salesforce.
Cada nueva consulta satisfactoria crea otra instantánea; no repetirla como lectura.
