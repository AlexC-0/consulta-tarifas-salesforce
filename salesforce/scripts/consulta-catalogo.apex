// Demostración fase 2: llamadas reales sin DML; salida limitada a evidencia no sensible.
List<String> products = new List<String>{'PROD-001', 'PROD-002', 'PROD-003', 'PROD-999'};
List<Integer> quantities = new List<Integer>{3, 2, 7, 1};
List<Decimal> expectedTotals = new List<Decimal>{59.70, 251.00, 6.93, null};
for (Integer i = 0; i < products.size(); i++) {
    try {
        P05ConsultaTarifa.Tarifa quote = P05ConsultaTarifa.consultar(products[i], quantities[i]);
        System.assert(i < 3, 'El producto desconocido debe rechazarse.');
        System.assertEquals(expectedTotals[i], quote.totalPrice);
        System.debug(LoggingLevel.INFO, JSON.serialize(new Map<String, Object>{
            'phase' => '2', 'productCode' => quote.productCode, 'quantity' => quote.quantity,
            'httpStatus' => quote.httpStatus, 'requestId' => quote.requestId,
            'quoteId' => quote.quoteId, 'currency' => quote.currencyCode,
            'unitPrice' => quote.unitPrice, 'totalPrice' => quote.totalPrice,
            'issuedAt' => quote.issuedAt, 'validUntil' => quote.validUntil,
            'tariffVersion' => quote.tariffVersion
        }));
    } catch (P05ConsultaTarifa.ConsultaException ex) {
        String category = ex.getMessage().substringBefore(' (requestId=');
        System.assertEquals(3, i, 'Una consulta de catálogo ha fallado.');
        System.assertEquals('PRODUCT_NOT_FOUND', category);
        String requestId = ex.getMessage().substringAfter('requestId=').substringBefore(')');
        System.debug(LoggingLevel.INFO, JSON.serialize(new Map<String, Object>{
            'phase' => '2', 'productCode' => products[i], 'quantity' => quantities[i],
            'category' => category, 'requestId' => requestId
        }));
    }
}
System.assertEquals(0, Limits.getDmlStatements());
