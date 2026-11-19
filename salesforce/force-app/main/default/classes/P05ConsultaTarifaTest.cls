@IsTest
private class P05ConsultaTarifaTest {
    private class ProviderMock implements HttpCalloutMock {
        Integer status = 200;
        String expectedCode = 'PROD-001';
        Integer expectedQuantity = 3;
        String unitPrice = '19.90';
        String totalPrice = '59.70';
        String tariffVersion = 'demo-1';
        Set<String> requestIds = new Set<String>();
        Integer issuedOffsetSeconds = -2;
        Integer durationSeconds = 86400;
        String invalidField;
        Object invalidValue;
        Boolean malformed = false;
        Boolean timeout = false;
        Boolean connectionError = false;
        String contentType = 'application/json; charset=utf-8';
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('callout:P05_Proveedor/v1/tarifas/consultar', request.getEndpoint());
            System.assertEquals('POST', request.getMethod());
            System.assertEquals('application/json', request.getHeader('Content-Type'));
            System.assertEquals(null, request.getHeader('X-API-Key'), 'El secreto lo incorpora Salesforce.');
            System.assertEquals(0, Limits.getDmlStatements());
            System.assert(Pattern.matches(
                '(?i)^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
                request.getHeader('X-Request-Id')));
            Map<String, Object> input = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
            System.assertEquals(expectedCode, input.get('productCode'));
            System.assertEquals(expectedQuantity, input.get('quantity'));
            System.assertEquals(2, input.size());
            String requestId = request.getHeader('X-Request-Id');
            System.assert(!requestIds.contains(requestId), 'Cada intento genera un UUID nuevo.');
            requestIds.add(requestId);
            if (timeout) {
                throw new CalloutException('Read timed out');
            }
            if (connectionError) {
                throw new CalloutException('Private transport detail');
            }
            Datetime issued = Datetime.now().addSeconds(issuedOffsetSeconds);
            Map<String, Object> body = new Map<String, Object>{
                'schemaVersion' => '1', 'requestId' => request.getHeader('X-Request-Id'),
                'quoteId' => UUID.randomUUID().toString(), 'productCode' => expectedCode,
                'quantity' => expectedQuantity, 'currency' => 'EUR', 'unitPrice' => unitPrice,
                'totalPrice' => totalPrice, 'issuedAt' => iso(issued),
                'validUntil' => iso(issued.addSeconds(durationSeconds)), 'tariffVersion' => tariffVersion
            };
            if (invalidField != null) {
                body.put(invalidField, invalidValue);
            }
            HttpResponse response = new HttpResponse();
            response.setStatusCode(status);
            response.setHeader('Content-Type', contentType);
            response.setBody(malformed || status != 200 ? '<html>private upstream error</html>' : JSON.serialize(body));
            return response;
        }
    }
    private static String iso(Datetime value) {
        return value.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }
    private static void expectFailure(ProviderMock mock, String expected) {
        Test.setMock(HttpCalloutMock.class, mock);
        Integer before = Limits.getCallouts();
        Boolean failed = false;
        try {
            P05ConsultaTarifa.consultar(mock.expectedCode, mock.expectedQuantity);
        } catch (P05ConsultaTarifa.ConsultaException ex) {
            failed = true;
            System.assert(ex.getMessage().startsWith(expected + ' (requestId='), ex.getMessage());
            System.assert(!ex.getMessage().contains('private'));
        }
        System.assert(failed, 'Debe rechazar ' + expected);
        System.assertEquals(before + 1, Limits.getCallouts(), 'No hay reintentos.');
        System.assertEquals(0, Limits.getDmlStatements());
    }
    @IsTest static void acceptsValidQuote() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock());
        Test.startTest();
        P05ConsultaTarifa.Tarifa result = P05ConsultaTarifa.consultarDemo();
        System.assertEquals(1, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());
        Test.stopTest();
        System.assertEquals(200, result.httpStatus);
        System.assertEquals('PROD-001', result.productCode);
        System.assertEquals(3, result.quantity);
        System.assertEquals('EUR', result.currencyCode);
        System.assertEquals(19.90, result.unitPrice);
        System.assertEquals(59.70, result.totalPrice);
        System.assertEquals(86400000, result.validUntil.getTime() - result.issuedAt.getTime());
        System.assert(result.receivedAt <= Datetime.now());
    }
    @IsTest static void temporalBoundariesPreserveExactDurationAndExpiry() {
        Datetime received = Datetime.newInstanceGmt(2026, 11, 19, 12, 0, 0);
        for (Integer offset : new List<Integer>{-1, 0, 13, 999, 1000}) {
            Datetime issued = Datetime.newInstance(received.getTime() + offset);
            P05ConsultaTarifa.validateTimes(issued, issued.addHours(24), received);
        }
        for (Integer offset : new List<Integer>{1001, 2000, -86400000, -86400001}) {
            Datetime issued = Datetime.newInstance(received.getTime() + offset);
            try {
                P05ConsultaTarifa.validateTimes(issued, issued.addHours(24), received);
                System.assert(false, 'Debe rechazar emisión fuera del margen o caducidad sin gracia.');
            } catch (P05ConsultaTarifa.ConsultaException ex) { System.assertEquals('Respuesta incoherente.', ex.getMessage()); }
        }
        P05ConsultaTarifa.validateTimes(Datetime.newInstance(received.getTime()-86399999),
            Datetime.newInstance(received.getTime()+1), received);
        for (Integer drift : new List<Integer>{-1, 1}) {
            try {
                P05ConsultaTarifa.validateTimes(received, Datetime.newInstance(received.getTime()+86400000+drift), received);
                System.assert(false, 'La duración debe ser exacta al milisegundo.');
            } catch (P05ConsultaTarifa.ConsultaException ex) { System.assertEquals('Respuesta incoherente.', ex.getMessage()); }
        }
    }
    @IsTest static void acceptsSmallFutureEmissionThroughHttpClient() {
        ProviderMock mock = new ProviderMock(); mock.issuedOffsetSeconds = 1;
        Test.setMock(HttpCalloutMock.class, mock);
        P05ConsultaTarifa.Tarifa quote = P05ConsultaTarifa.consultarDemo();
        System.assert(quote.issuedAt.getTime() <= quote.receivedAt.getTime()+1000);
        System.assertEquals(86400000, quote.validUntil.getTime()-quote.issuedAt.getTime());
        System.assertEquals(1, Limits.getCallouts());
    }
    @IsTest static void mapsHttpErrorsWithoutTrustingBody() {
        Map<Integer, String> cases = new Map<Integer, String>{
            400 => 'INVALID_REQUEST', 401 => 'UNAUTHORIZED', 404 => 'PRODUCT_NOT_FOUND',
            429 => 'RATE_LIMITED', 500 => 'INTERNAL_ERROR', 503 => 'PROVIDER_UNAVAILABLE',
            302 => 'HTTP_ERROR', 403 => 'HTTP_ERROR'
        };
        for (Integer status : cases.keySet()) {
            ProviderMock mock = new ProviderMock();
            mock.status = status;
            expectFailure(mock, cases.get(status));
        }
    }
    @IsTest static void rejectsMalformedBodyAndWrongContentType() {
        ProviderMock mock = new ProviderMock();
        mock.malformed = true;
        expectFailure(mock, 'INVALID_RESPONSE');
        mock = new ProviderMock();
        mock.contentType = 'text/html';
        expectFailure(mock, 'INVALID_RESPONSE');
    }
    @IsTest static void rejectsInconsistentFields() {
        Map<String, Object> cases = new Map<String, Object>{
            'requestId' => UUID.randomUUID().toString(), 'quoteId' => 'invalid',
            'schemaVersion' => '2', 'productCode' => 'PROD-002', 'quantity' => '3',
            'currency' => 'USD', 'unitPrice' => '19.9', 'totalPrice' => '59.71',
            'tariffVersion' => '', 'extra' => 'unexpected'
        };
        for (String field : cases.keySet()) {
            ProviderMock mock = new ProviderMock();
            mock.invalidField = field;
            mock.invalidValue = cases.get(field);
            expectFailure(mock, 'INVALID_RESPONSE');
        }
    }
    @IsTest static void rejectsInvalidAmounts() {
        for (Object price : new List<Object>{ 19.90, '0.00', '-19.90', '1000000.00', '019.90', '19.900', '1e2', null }) {
            ProviderMock mock = new ProviderMock();
            mock.invalidField = 'unitPrice';
            mock.invalidValue = price;
            expectFailure(mock, 'INVALID_RESPONSE');
        }
    }
    @IsTest static void rejectsExpiredFutureAndWrongDuration() {
        for (Datetime expiry : new List<Datetime>{ Datetime.now().addSeconds(-1), Datetime.now().addHours(25) }) {
            ProviderMock mock = new ProviderMock();
            mock.invalidField = 'validUntil';
            mock.invalidValue = iso(expiry);
            expectFailure(mock, 'INVALID_RESPONSE');
        }
        ProviderMock mock = new ProviderMock();
        mock.invalidField = 'issuedAt';
        mock.invalidValue = iso(Datetime.now().addHours(1));
        expectFailure(mock, 'INVALID_RESPONSE');
        mock.invalidValue = 'not-a-date';
        expectFailure(mock, 'INVALID_RESPONSE');
    }
    @IsTest static void mapsTimeoutAndConnectionErrors() {
        ProviderMock mock = new ProviderMock();
        mock.timeout = true;
        expectFailure(mock, 'TIMEOUT');
        mock = new ProviderMock();
        mock.connectionError = true;
        expectFailure(mock, 'CONNECTION_ERROR');
    }
    @IsTest static void rejectsWrongCaseAndQuantity() {
        Map<String, Object> cases = new Map<String, Object>{
            'productCode' => 'prod-001', 'currency' => 'eur',
            'schemaVersion' => 1, 'quantity' => 4
        };
        for (String field : cases.keySet()) {
            ProviderMock mock = new ProviderMock();
            mock.invalidField = field;
            mock.invalidValue = cases.get(field);
            expectFailure(mock, 'INVALID_RESPONSE');
        }
    }

    @IsTest static void acceptsVariableProductsAndQuantities() {
        List<String> products = new List<String>{'PROD-002', 'PROD-003', 'PROD-123'};
        List<Integer> quantities = new List<Integer>{2, 7, 10000};
        List<String> units = new List<String>{'125.50', '0.99', '999999.99'};
        List<String> totals = new List<String>{'251.00', '6.93', '9999999900.00'};
        for (Integer i = 0; i < products.size(); i++) {
            ProviderMock mock = new ProviderMock();
            mock.expectedCode = products[i]; mock.expectedQuantity = quantities[i];
            mock.unitPrice = units[i]; mock.totalPrice = totals[i];
            Test.setMock(HttpCalloutMock.class, mock);
            Integer before = Limits.getCallouts();
            P05ConsultaTarifa.Tarifa result = P05ConsultaTarifa.consultar(products[i], quantities[i]);
            System.assertEquals(products[i], result.productCode);
            System.assertEquals(quantities[i], result.quantity);
            System.assertEquals(Decimal.valueOf(units[i]), result.unitPrice);
            System.assertEquals(Decimal.valueOf(totals[i]), result.totalPrice);
            System.assertEquals(before + 1, Limits.getCallouts());
            System.assertEquals(0, Limits.getDmlStatements());
        }
    }
    @IsTest static void acceptsMinimumAndChangedPriceAndTariffVersion() {
        ProviderMock mock = new ProviderMock();
        mock.expectedQuantity = 1;
        mock.unitPrice = '20.00'; mock.totalPrice = '20.00';
        mock.tariffVersion = 'tarifa-2026-B';
        Test.setMock(HttpCalloutMock.class, mock);
        P05ConsultaTarifa.Tarifa result = P05ConsultaTarifa.consultar('PROD-001', 1);
        System.assertEquals(20.00, result.unitPrice);
        System.assertEquals(20.00, result.totalPrice);
        System.assertEquals('tarifa-2026-B', result.tariffVersion);
        System.assertEquals(1, result.quantity);
        System.assertEquals(1, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());
    }
    private static void expectInvalidInput(String code, Decimal quantity) {
        Integer before = Limits.getCallouts();
        try {
            P05ConsultaTarifa.consultar(code, quantity);
            System.assert(false, 'Entrada inválida aceptada.');
        } catch (P05ConsultaTarifa.ConsultaException ex) {
            System.assert(ex.getMessage().startsWith('INVALID_REQUEST (requestId='));
        }
        System.assertEquals(before, Limits.getCallouts(), 'No debe realizar callout.');
        System.assertEquals(0, Limits.getDmlStatements());
    }
    @IsTest static void rejectsInvalidInputBeforeCallout() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock());
        for (String code : new List<String>{null, '', ' ', 'prod-001', ' PROD-001', 'PROD-001 ', 'PROD-01', 'PROD-1000', 'https://example.invalid'}) {
            expectInvalidInput(code, 3);
        }
        for (Decimal quantity : new List<Decimal>{null, 0, -1, 1.5, 9999.9, 10000.1, 10001}) {
            expectInvalidInput('PROD-001', quantity);
        }
    }
    @IsTest static void delegatesUnknownProductToProvider() {
        ProviderMock mock = new ProviderMock();
        mock.expectedCode = 'PROD-999'; mock.expectedQuantity = 1; mock.status = 404;
        expectFailure(mock, 'PRODUCT_NOT_FOUND');
    }
    @IsTest static void rejectsInvalidVersionsAndQuantityTypes() {
        for (Object version : new List<Object>{null, '', '   ', 1, 'x'.repeat(65)}) {
            ProviderMock mock = new ProviderMock();
            mock.invalidField = 'tariffVersion'; mock.invalidValue = version;
            expectFailure(mock, 'INVALID_RESPONSE');
        }
        for (Object quantity : new List<Object>{null, true, '3', 3.1}) {
            ProviderMock mock = new ProviderMock();
            mock.invalidField = 'quantity'; mock.invalidValue = quantity;
            expectFailure(mock, 'INVALID_RESPONSE');
        }
        ProviderMock mock = new ProviderMock();
        mock.tariffVersion = 'v'.repeat(64);
        Test.setMock(HttpCalloutMock.class, mock);
        System.assertEquals(mock.tariffVersion, P05ConsultaTarifa.consultarDemo().tariffVersion);
    }
    @IsTest static void rejectsTotalPrecisionTypeAndMismatch() {
        for (Object total : new List<Object>{59.70, '59.700', '59.7', '-59.70', '0.00', '59.71', '10000000000.00', null}) {
            ProviderMock mock = new ProviderMock();
            mock.invalidField = 'totalPrice'; mock.invalidValue = total;
            expectFailure(mock, 'INVALID_RESPONSE');
        }
    }
    @IsTest static void rejectsExpiredAndFutureEvenWithCorrectDuration() {
        ProviderMock mock = new ProviderMock();
        mock.issuedOffsetSeconds = -86402;
        expectFailure(mock, 'INVALID_RESPONSE');
        mock = new ProviderMock(); mock.issuedOffsetSeconds = 3600;
        expectFailure(mock, 'INVALID_RESPONSE');
        mock = new ProviderMock(); mock.durationSeconds = 86401;
        expectFailure(mock, 'INVALID_RESPONSE');
    }
    @IsTest static void generatesNewRequestIdForEachAttempt() {
        ProviderMock mock = new ProviderMock();
        Test.setMock(HttpCalloutMock.class, mock);
        String first = P05ConsultaTarifa.consultarDemo().requestId;
        String second = P05ConsultaTarifa.consultarDemo().requestId;
        System.assertNotEquals(first, second);
        System.assertEquals(2, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());
    }
}
