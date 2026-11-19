# Alcance de P05

**V1 completada y aceptada dentro del alcance documentado, con limitaciones conocidas.**
Aceptación definitiva del 19/11/2026 sobre la revisión final publicada en
`061485df3455dab9296950a7bdf5df33630ab069`.
Fase 5B publicada en `756e931dbb2e78f4d3bdf64c762738f71344e976`; funcionalidad de
fase 5 en `3f6a4dcd9aa08ce3884a78ef9dc252cf684ede16`. Revisión documental de fase 6.
El perfil funcional es un comercial de demostración, con proveedor y datos simulados.
Selecciona producto y cantidad y pulsa **Consultar y guardar tarifa**.

Recorrido implementado:
LWC → Apex → Named Credential → API HTTPS → validación Apex → instantánea Salesforce → LWC.

## Reglas de V1

- Tres productos ficticios; cantidad entera entre 1 y 10.000; EUR exclusivamente.
- Precio unitario fijo positivo, dos decimales, máximo 999999.99.
- Total = precio unitario × cantidad. Sin descuentos, impuestos, pagos, pedidos ni reservas.
- Importes JSON como cadenas con dos decimales; cálculo en céntimos enteros.
- Vigencia de 24 horas exactas desde emisión. Emisión futura: máximo 1000 ms respecto
  a recepción. Caducidad sin tolerancia y comprobada de nuevo al guardar. Las demás
  incoherencias siguen implicando rechazo.
- Éxito: nueva instantánea guardada automáticamente. Error: ninguna instantánea válida.
- Histórico sin actualización automática. Nueva consulta, nueva instantánea.
- Sin reintentos automáticos; timeout Apex inicial de diez segundos.
- No confiar en importes ni respuestas del proveedor aportados por el navegador.

La formulación original «Sin reintentos automáticos» se conserva. La aceptación
final del 19/11/2026 la delimita a reintentos programados en la aplicación; no
garantiza entrega física única ni idempotencia entre acciones separadas. Se acepta
la limitación externa 429/503, cuyo componente causante no está identificado.
Véase la [matriz y aceptación](ACEPTACION-V1.md).
No cambia el contrato, no oculta el hallazgo ni añade mecanismos de deduplicación.

La instalación limpia no figura como criterio aprobado en las reglas originales
del brief (`603ebd1`). Las fases 3–5B la registran como verificación no ejecutada.
Se conserva esa limitación y se documenta el procedimiento; no se convierte por
defecto en una ampliación obligatoria. Queda aceptado el despliegue incremental
comprobado y la instalación limpia documentada y revisada estáticamente, sin
ejecución desde cero. Ninguna de estas dos limitaciones es una tarea obligatoria
pendiente de V1. [Fuentes y distinción](ACEPTACION-V1.md#instalacion).

## Modelo implementado en fase 3

Product2 con CodigoProveedor__c único. ConsultaTarifa__c con autonumérico,
producto, código y nombre copiados, cantidad, precio unitario, total, moneda,
fechas de emisión/recepción/caducidad, requestId, quoteId y versión de tarifa.
Importes Number de dos decimales y moneda explícita. Consultas privadas por defecto;
comerciales sin edición ni borrado; creación controlada desde la integración.

## Fase 1 — antecedente

Un producto PROD-001 a 19.90 EUR, API sin base de datos, autenticación, validación,
health mínimo, logs de requestId/estado/duración y pruebas locales.
Cliente Apex fijo de diagnóstico, sin argumentos, DML ni interfaz de usuario.
HttpCalloutMock preparado; callout real sujeto a organización, credenciales y
túnel disponibles. Contrato en openapi.json.

Código, Git, organización, datos y credenciales independientes de P01–P04.
Relación conceptual entre proyectos de aprendizaje; ninguna integración entre
ellos autorizada o implementada. Sin Gmail, servicios de pago, comunicaciones
reales ni cambios globales de herramientas.

## Fase 2 — completada

Catálogo ficticio completo: PROD-001 a 19.90 EUR, PROD-002 a 125.50 EUR
y PROD-003 a 0.99 EUR. Fuente de precios de ejecución: proveedor/src/app.ts,
en céntimos enteros. Endpoint y estructura de respuesta conservados.

Cliente Apex interno consultar(String productCode, Decimal quantity), sin DML
ni @AuraEnabled. Valida entradas antes del callout y respuestas sin precios
incrustados ni lista local de productos. consultarDemo() conserva el caso original.
schemaVersion="1"; tariffVersion de 1 a 64 caracteres, no solo espacios.
Detalle en [CLIENTE_APEX](CLIENTE_APEX.md) y [STATUS](STATUS.md).

Demostrados los tres productos y PRODUCT_NOT_FOUND/404 desde Apex mediante HTTPS.
La organización y las credenciales de fase 1B se reutilizan. Seguridad comercial,
Product2, persistencia e interfaz quedan para fases posteriores.
## Fase 3 — servicio y persistencia

Product2 con código único y ConsultaTarifa__c privada. El servicio recibe Id de
producto y cantidad; resuelve nombre/código, aplica autorización y CRUD/FLS,
consulta al proveedor y guarda la respuesta validada en USER_MODE.

Un contexto privado de un solo uso permite únicamente el insert del servicio.
El trigger rechaza altas directas, edición, borrado y recuperación. El lookup
SetNull conserva la instantánea si se elimina el producto. Sus copias de nombre,
código y valores económicos permanecen intactas.

Histórico propio acotado y detalle autorizado, sin callouts; las tarifas caducadas
siguen legibles y la vigencia se calcula al leer. Sin LWC ni adaptadores Aura.
Detalles en [MODELO](MODELO.md), [SEGURIDAD](SEGURIDAD.md) y [PERSISTENCIA](PERSISTENCIA.md).
## Fase 4 — interfaz y recorrido comercial completados

LWC p05Tarifas, controlador with sharing y DTO de nivel superior. Aplicación/pestaña
P05 y permisos mínimos versionados. Consulta/guardado delegados al servicio anterior,
histórico propio sin proveedor, errores seguros y caducidad visual dinámica.

Recorrido comercial real, propiedad/autoría, detalle ajeno denegado y lectura offline
comprobados. 36/36 Apex y 21/21 Jest. Fase 5 conserva la matriz final de fallos reales
y revisión de robustez temporal; en aquel estado la V1 aún no se declaró terminada.

## Fase 5 — robustez temporal y fallos

Margen fijo de emisión, marca de recepción capturada una vez, vigencia al guardar y referencia temporal
Salesforce para la interfaz. Pruebas de fronteras y suspensión, banco aislado y
matriz diferenciada entre mocks, HTTP local, callout Salesforce y LWC comercial.
Sin ampliaciones de negocio, nuevos permisos amplios o cambios de reloj.
Resultados, criterios V1 y limitaciones en [STATUS](STATUS.md) y [FASE-5](FASE-5.md).

## Fases 5B y 6

5B confirma dos entradas HTTP distintas ante 429/503 por un callout Apex, frente
a una en los controles Node; no identifica el componente externo ni demuestra
reintento propio. Sus sondas no alteran instantáneas. [Diagnóstico](FASE-5B.md).
Fase 6 consolidó aceptación propuesta, reproducción y ficha técnica mediante revisión
estática, sin nuevas funcionalidades, ejecuciones externas ni cierre en aquella revisión.
La aceptación actual cierra V1 con las limitaciones indicadas; esta actualización
documental local aún no está publicada y no representa pruebas nuevas.
