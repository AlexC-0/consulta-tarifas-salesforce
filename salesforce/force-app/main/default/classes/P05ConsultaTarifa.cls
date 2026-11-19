/**
 * Sonda de sesión 1: una consulta fija, sin DML, interfaz LWC ni secretos.
 * La Named Credential P05_Proveedor incorpora X-API-Key.
 */
public with sharing class P05ConsultaTarifa {
    public class ConsultaException extends Exception {}
    public class Tarifa {
        public String requestId;
        public String quoteId;
        public String productCode;
        public Integer quantity;
        public String currency;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Datetime issuedAt;
        public Datetime validUntil;
        public String tariffVersion;
        public Integer httpStatus;
    }
    private static final String UUID_REGEX =
        '(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

    public static Tarifa consultarDemo() {
        String requestId = UUID.randomUUID().toString();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:P05_Proveedor/v1/tarifas/consultar');
        request.setMethod('POST');
        request.setTimeout(10000);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('X-Request-Id', requestId);
        request.setBody(JSON.serialize(new Map<String, Object>{
            'productCode' => 'PROD-001', 'quantity' => 3
        }));
        HttpResponse response;
        try {
            response = new Http().send(request);
        } catch (CalloutException ex) {
            String category = ex.getMessage().toLowerCase().contains('timed out') ?
                'TIMEOUT' : 'CONNECTION_ERROR';
            throw failure(category, requestId);
        }
        if (response.getStatusCode() != 200) {
            Map<Integer, String> errors = new Map<Integer, String>{
                400 => 'INVALID_REQUEST', 401 => 'UNAUTHORIZED',
                404 => 'PRODUCT_NOT_FOUND', 429 => 'RATE_LIMITED',
                500 => 'INTERNAL_ERROR', 503 => 'PROVIDER_UNAVAILABLE'
            };
            String category = errors.get(response.getStatusCode());
            throw failure(category == null ? 'HTTP_ERROR' : category, requestId);
        }
        try {
            String contentType = response.getHeader('Content-Type');
            require(contentType != null &&
                contentType.toLowerCase().split(';')[0].trim() == 'application/json');
            require(response.getBody() != null && response.getBody().length() <= 8192);
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            require(data != null);
            require(data.keySet().equals(new Set<String>{
                'schemaVersion', 'requestId', 'quoteId', 'productCode', 'quantity',
                'currency', 'unitPrice', 'totalPrice', 'issuedAt', 'validUntil', 'tariffVersion'
            }));
            require(text(data, 'schemaVersion').equals('1'));
            require(text(data, 'requestId').equals(requestId));
            require(text(data, 'productCode').equals('PROD-001'));
            Object quantity = data.get('quantity');
            require(quantity instanceof Integer || quantity instanceof Long || quantity instanceof Decimal);
            require(Decimal.valueOf(String.valueOf(quantity)) == 3);
            require(text(data, 'currency').equals('EUR'));
            require(text(data, 'tariffVersion').equals('demo-1'));
            String quoteId = text(data, 'quoteId');
            require(Pattern.matches(UUID_REGEX, quoteId));
            Decimal unitPrice = amount(text(data, 'unitPrice'), 6);
            Decimal totalPrice = amount(text(data, 'totalPrice'), 10);
            require(unitPrice > 0 && unitPrice <= 999999.99);
            require(unitPrice == 19.90 && totalPrice == unitPrice * 3);
            Datetime issuedAt = utc(text(data, 'issuedAt'));
            Datetime validUntil = utc(text(data, 'validUntil'));
            Datetime receivedAt = Datetime.now();
            require(issuedAt <= receivedAt && validUntil > receivedAt);
            require(validUntil.getTime() - issuedAt.getTime() == 86400000);
            Tarifa result = new Tarifa();
            result.requestId = requestId;
            result.quoteId = quoteId;
            result.productCode = 'PROD-001';
            result.quantity = 3;
            result.currency = 'EUR';
            result.unitPrice = unitPrice;
            result.totalPrice = totalPrice;
            result.issuedAt = issuedAt;
            result.validUntil = validUntil;
            result.tariffVersion = 'demo-1';
            result.httpStatus = 200;
            return result;
        } catch (Exception ex) {
            throw failure('INVALID_RESPONSE', requestId);
        }
    }
    private static String text(Map<String, Object> data, String key) {
        require(data.get(key) instanceof String);
        return (String) data.get(key);
    }
    private static Decimal amount(String value, Integer digits) {
        require(Pattern.matches('^(0|[1-9][0-9]{0,' + (digits - 1) + '})\\.[0-9]{2}$', value));
        return Decimal.valueOf(value);
    }
    private static Datetime utc(String value) {
        require(Pattern.matches('^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\.[0-9]{3}Z$', value));
        Datetime parsed = (Datetime) JSON.deserialize(JSON.serialize(value), Datetime.class);
        require(parsed.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') == value);
        return parsed;
    }
    private static void require(Boolean condition) {
        if (!condition) {
            throw new ConsultaException('Respuesta incoherente.');
        }
    }
    private static ConsultaException failure(String category, String requestId) {
        return new ConsultaException(category + ' (requestId=' + requestId + ')');
    }
}
