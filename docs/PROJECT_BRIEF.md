# Alcance de P05

Un comercial seleccionará producto y cantidad y pulsará **Consultar y guardar tarifa**.

Recorrido previsto:
LWC → Apex → Named Credential → API HTTPS → validación Apex → instantánea Salesforce → LWC.

## Reglas de V1

- Tres productos ficticios; cantidad entera entre 1 y 10.000; EUR exclusivamente.
- Precio unitario fijo positivo, dos decimales, máximo 999999.99.
- Total = precio unitario × cantidad. Sin descuentos, impuestos, pagos, pedidos ni reservas.
- Importes JSON como cadenas con dos decimales; cálculo en céntimos enteros.
- Vigencia de 24 horas desde emisión. Caducidad o incoherencia implica rechazo.
- Éxito: nueva instantánea guardada automáticamente. Error: ninguna instantánea válida.
- Histórico sin actualización automática. Nueva consulta, nueva instantánea.
- Sin reintentos automáticos; timeout Apex inicial de diez segundos.
- No confiar en importes ni respuestas del proveedor aportados por el navegador.

## Modelo implementado en fase 3

Product2 con CodigoProveedor__c único. ConsultaTarifa__c con autonumérico,
producto, código y nombre copiados, cantidad, precio unitario, total, moneda,
fechas de emisión/recepción/caducidad, requestId, quoteId y versión de tarifa.
Importes Number de dos decimales y moneda explícita. Consultas privadas por defecto;
comerciales sin edición ni borrado; creación controlada desde la integración.

## Sesión 1 — antecedente

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
La organización y las credenciales de sesión 1B se reutilizan. Seguridad comercial,
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