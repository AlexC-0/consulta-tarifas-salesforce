// Ejecutar SOLO en P05, con Named Credential configurada y túnel autorizado.
// No imprime cabeceras, credenciales ni cuerpos externos.
P05ConsultaTarifa.Tarifa tarifa = P05ConsultaTarifa.consultarDemo();
System.debug(LoggingLevel.INFO, JSON.serialize(new Map<String, Object>{
    'httpStatus' => tarifa.httpStatus,
    'requestId' => tarifa.requestId,
    'quoteId' => tarifa.quoteId,
    'productCode' => tarifa.productCode,
    'quantity' => tarifa.quantity,
    'currency' => tarifa.currency,
    'unitPrice' => tarifa.unitPrice,
    'totalPrice' => tarifa.totalPrice,
    'issuedAt' => tarifa.issuedAt,
    'validUntil' => tarifa.validUntil
}));
