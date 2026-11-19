# Cliente Apex — fase 2

Operación interna: `P05ConsultaTarifa.consultar(String productCode, Decimal quantity)`.
No es @AuraEnabled, no recibe URLs ni secretos y no realiza DML.
`consultarDemo()` delega en la misma operación con PROD-001 y cantidad 3.

## Entradas

- Código obligatorio, exactamente `^PROD-[0-9]{3}$`, sin normalizar espacios o mayúsculas.
- Cantidad Decimal obligatoria, valor matemáticamente entero entre 1 y 10.000.
  Se comprueba fracción y rango antes de convertir a Integer. No se redondea la
  entrada para aceptarla; 1.5 y 9999.9 se rechazan sin callout.
- Se genera un UUID para correlacionar cada intento, también si la entrada se rechaza.
- Un código válido desconocido llega al proveedor y puede producir 404.
  No hay lista de productos ni precios de catálogo dentro del cliente.

La capa P05TarifasServicio de fase 3 resuelve el código desde Product2, comprueba permisos y guarda la instantánea. Este cliente HTTP permanece independiente y sin DML.

## Petición y respuesta

Un único POST a `callout:P05_Proveedor/v1/tarifas/consultar`, timeout de 10 segundos,
sin reintentos. Salesforce incorpora la clave protegida desde la Named Credential.

Respuesta 200: Content-Type JSON, máximo 8192 caracteres y conjunto exacto de campos
del contrato. Producto, cantidad y requestId deben coincidir con la petición.
UUID válido para quoteId, moneda EUR exacta y cantidades numéricas, no cadenas.

Importes JSON como cadenas decimales canónicas con dos decimales, sin ceros iniciales
innecesarios, signos ni notación científica. Unitario positivo hasta 999999.99;
total de hasta diez dígitos enteros y exactamente unitario × cantidad.
Se acepta un precio diferente al catálogo local si cumple esas condiciones:
la autenticidad de la conexión y la coherencia se comprueban sin duplicar precios.

`schemaVersion` es la cadena "1" y representa el contrato.
`tariffVersion` identifica la tarifa: cadena de 1 a 64 caracteres y no compuesta
solo por espacios. No se transforma ni se exige "demo-1"; el proveedor mantiene
ese identificador en los ejemplos actuales. No confundir ambas versiones.

Fechas UTC canónicas con milisegundos y Z; se valida que la fecha exista mediante
conversión y comparación de vuelta. Emisión no futura, vencimiento posterior
a recepción y duración exacta de 86.400.000 ms. Sin tolerancias añadidas al reloj.

DTO: `currencyCode` internamente; el contrato JSON conserva `currency`.
Devuelve producto/cantidad, importes, IDs, fechas, tarifa y estado HTTP; sin guardado.

## Errores

Solo se expone categoría y requestId. No se devuelve el cuerpo externo ni el
detalle de conexión. HTTP 400 → INVALID_REQUEST, 401 → UNAUTHORIZED,
404 → PRODUCT_NOT_FOUND, 429 → RATE_LIMITED, 500 → INTERNAL_ERROR,
503 → PROVIDER_UNAVAILABLE; otros → HTTP_ERROR.
Timeout → TIMEOUT, otros fallos de transporte → CONNECTION_ERROR.
Respuesta 200 incoherente → INVALID_RESPONSE.
Los errores HTTP se clasifican sin confiar en su cuerpo, que puede ser HTML.

## Verificación

16 métodos Apex: caso original, productos/cantidades variables, límites,
precio alternativo, versión de tarifa alternativa y límite de longitud,
entradas inválidas sin callouts, 404, discordancias, tipos, precisión, fechas,
errores HTTP/transporte, UUID por intento, ausencia de DML y reintentos.

El mock acepta incluso PROD-123 para comprobar que el cliente no impone el catálogo.
Pruebas aisladas no acreditan red ni permisos comerciales.
La demostración real está en [STATUS](STATUS.md) y
[evidencias-fase-2.json](evidencias-fase-2.json).
