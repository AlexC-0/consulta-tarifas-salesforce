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

## Modelo posterior, no implementado en sesión 1

Product2 con CodigoProveedor__c único. ConsultaTarifa__c con autonumérico,
producto, código y nombre copiados, cantidad, precio unitario, total, moneda,
fechas de emisión/recepción/caducidad, requestId, quoteId y versión de tarifa.
Importes Number de dos decimales y moneda explícita. Consultas privadas por defecto;
comerciales sin edición ni borrado; creación controlada desde la integración.

## Sesión 1

Un producto PROD-001 a 19.90 EUR, API sin base de datos, autenticación, validación,
health mínimo, logs de requestId/estado/duración y pruebas locales.
Cliente Apex fijo de diagnóstico, sin argumentos, DML ni interfaz de usuario.
HttpCalloutMock preparado; callout real sujeto a organización, credenciales y
túnel disponibles. Contrato en openapi.json.

Código, Git, organización, datos y credenciales independientes de P01–P04.
Relación conceptual entre proyectos de aprendizaje; ninguna integración entre
ellos autorizada o implementada. Sin Gmail, servicios de pago, comunicaciones
reales ni cambios globales de herramientas.
