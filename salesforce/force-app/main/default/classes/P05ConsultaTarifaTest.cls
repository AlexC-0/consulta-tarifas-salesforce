@IsTest
private class P05ConsultaTarifaTest {
    private class ProviderMock implements HttpCalloutMock {
        Integer status = 200;
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
            System.assertEquals('PROD-001', input.get('productCode'));
            System.assertEquals(3, input.get('quantity'));
            if (timeout) {
                throw new CalloutException('Read timed out');
            }
            if (connectionError) {
                throw new CalloutException('Private transport detail');
            }
            Datetime issued = Datetime.now().addSeconds(-2);
            Map<String, Object> body = new Map<String, Object>{
                'schemaVersion' => '1', 'requestId' => request.getHeader('X-Request-Id'),
                'quoteId' => UUID.randomUUID().toString(), 'productCode' => 'PROD-001',
                'quantity' => 3, 'currency' => 'EUR', 'unitPrice' => '19.90',
                'totalPrice' => '59.70', 'issuedAt' => iso(issued),
                'validUntil' => iso(issued.addHours(24)), 'tariffVersion' => 'demo-1'
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
            P05ConsultaTarifa.consultarDemo();
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
        System.assertEquals('EUR', result.currency);
        System.assertEquals(19.90, result.unitPrice);
        System.assertEquals(59.70, result.totalPrice);
        System.assertEquals(86400000, result.validUntil.getTime() - result.issuedAt.getTime());
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
            'tariffVersion' => 'demo-2', 'extra' => 'unexpected'
        };
        for (String field : cases.keySet()) {
            ProviderMock mock = new ProviderMock();
            mock.invalidField = field;
            mock.invalidValue = cases.get(field);
            expectFailure(mock, 'INVALID_RESPONSE');
        }
    }
    @IsTest static void rejectsInvalidAmounts() {
        for (Object price : new List<Object>{ 19.90, '0.00', '-19.90', '1000000.00', '019.90', '20.00', null }) {
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
            'tariffVersion' => 'DEMO-1', 'quantity' => 4
        };
        for (String field : cases.keySet()) {
            ProviderMock mock = new ProviderMock();
            mock.invalidField = field;
            mock.invalidValue = cases.get(field);
            expectFailure(mock, 'INVALID_RESPONSE');
        }
    }
}
