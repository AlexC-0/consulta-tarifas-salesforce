/**
 * Aplicación P05: autorización, consulta validada y persistencia en modo usuario.
 * No admite importes, código ni propietario aportados por el consumidor.
 */
public with sharing class P05TarifasServicio {
    public class ServicioException extends Exception {}
    public class Detalle {
        public ConsultaTarifa__c registro;
        public Boolean vigente;
        public String aviso;
        private Detalle(ConsultaTarifa__c record) {
            registro = record;
            vigente = record.CaducaEn__c > Datetime.now();
            aviso = 'Información obtenida en esta consulta; no se actualiza automáticamente';
        }
    }
    private static final List<String> SNAPSHOT_FIELDS = new List<String>{
        'Producto__c', 'NombreProducto__c', 'CodigoProveedor__c', 'Moneda__c', 'RequestId__c', 'QuoteId__c', 'TariffVersion__c', 'SchemaVersion__c', 'Cantidad__c', 'PrecioUnitario__c', 'Total__c', 'EmitidaEn__c', 'RecibidaEn__c', 'CaducaEn__c'
    };
    private static final String READ_FIELDS = 'Id,Name,OwnerId,CreatedById,CreatedDate,' +
        String.join(SNAPSHOT_FIELDS, ',');
    // Privado, no TestVisible y sin setter: solo consultarYGuardar puede abrirlo.
    private static ConsultaTarifa__c pendingInsert;

    public static Detalle consultarYGuardar(Id productId, Decimal quantity) {
        authorize();
        if (productId == null || productId.getSObjectType() != Product2.SObjectType ||
            quantity == null || quantity < 1 || quantity > 10000 || quantity != quantity.setScale(0)) {
            throw error('INVALID_REQUEST');
        }
        ensureReadAccess();
        if (!Product2.SObjectType.getDescribe().isAccessible() ||
            !Product2.Name.getDescribe().isAccessible() ||
            !Product2.IsActive.getDescribe().isAccessible() ||
            !Product2.CodigoProveedor__c.getDescribe().isAccessible() ||
            !ConsultaTarifa__c.SObjectType.getDescribe().isCreateable() ||
            !ConsultaTarifa__c.OwnerId.getDescribe().isCreateable()) {
            throw error('ACCESS_DENIED');
        }
        Map<String, Schema.SObjectField> fields = ConsultaTarifa__c.SObjectType.getDescribe().fields.getMap();
        for (String field : SNAPSHOT_FIELDS) {
            if (!fields.get(field).getDescribe().isCreateable()) { throw error('ACCESS_DENIED'); }
        }
        List<Product2> products;
        try {
            products = [SELECT Id, Name, IsActive, CodigoProveedor__c FROM Product2
                WHERE Id = :productId WITH USER_MODE LIMIT 1];
        } catch (QueryException ex) {
            throw error('ACCESS_DENIED');
        }
        if (products.isEmpty()) { throw error('PRODUCT_UNAVAILABLE'); }
        Product2 product = products[0];
        if (!product.IsActive || product.CodigoProveedor__c == null ||
            !Pattern.matches('^PROD-[0-9]{3}$', product.CodigoProveedor__c)) {
            throw error('PRODUCT_UNAVAILABLE');
        }
        // No DML ni savepoint antes de la llamada. El cliente conserva categoría y UUID.
        P05ConsultaTarifa.Tarifa quote = P05ConsultaTarifa.consultar(product.CodigoProveedor__c, quantity);
        Datetime receivedAt = Datetime.now();
        ConsultaTarifa__c snapshot = new ConsultaTarifa__c(
            OwnerId = UserInfo.getUserId(), Producto__c = product.Id,
            NombreProducto__c = product.Name, CodigoProveedor__c = product.CodigoProveedor__c,
            Cantidad__c = quote.quantity, PrecioUnitario__c = quote.unitPrice, Total__c = quote.totalPrice,
            Moneda__c = quote.currencyCode, EmitidaEn__c = quote.issuedAt,
            RecibidaEn__c = receivedAt, CaducaEn__c = quote.validUntil,
            RequestId__c = quote.requestId, QuoteId__c = quote.quoteId,
            TariffVersion__c = quote.tariffVersion, SchemaVersion__c = '1'
        );
        // El rollback cubre también una anomalía de lectura posterior al insert.
        Savepoint checkpoint = Database.setSavepoint();
        try {
            pendingInsert = snapshot.clone(false, false, false, false);
            insert as user snapshot;
            return obtener(snapshot.Id);
        } catch (Exception ex) {
            Database.rollback(checkpoint);
            throw new ServicioException('SAVE_FAILED (requestId=' + quote.requestId + ')');
        } finally {
            pendingInsert = null;
        }
    }

    public static Detalle obtener(Id snapshotId) {
        authorize();
        ensureReadAccess();
        if (snapshotId == null || snapshotId.getSObjectType() != ConsultaTarifa__c.SObjectType) {
            throw error('INVALID_REQUEST');
        }
        List<SObject> rows;
        try {
            rows = Database.queryWithBinds('SELECT ' + READ_FIELDS +
                ' FROM ConsultaTarifa__c WHERE Id = :snapshotId AND OwnerId = :ownerId LIMIT 1',
                new Map<String, Object>{'snapshotId' => snapshotId, 'ownerId' => UserInfo.getUserId()},
                AccessLevel.USER_MODE);
        } catch (QueryException ex) {
            throw error('ACCESS_DENIED');
        }
        if (rows.isEmpty()) { throw error('NOT_FOUND'); }
        return new Detalle((ConsultaTarifa__c) rows[0]);
    }

    public static List<Detalle> listarPropias(Integer maxResults) {
        authorize();
        ensureReadAccess();
        if (maxResults == null || maxResults < 1 || maxResults > 100) { throw error('INVALID_REQUEST'); }
        List<SObject> rows;
        try {
            rows = Database.queryWithBinds('SELECT ' + READ_FIELDS +
                ' FROM ConsultaTarifa__c WHERE OwnerId = :ownerId ORDER BY CreatedDate DESC, Id DESC LIMIT :maxResults',
                new Map<String, Object>{'ownerId' => UserInfo.getUserId(), 'maxResults' => maxResults},
                AccessLevel.USER_MODE);
        } catch (QueryException ex) {
            throw error('ACCESS_DENIED');
        }
        List<Detalle> results = new List<Detalle>();
        for (SObject row : rows) { results.add(new Detalle((ConsultaTarifa__c) row)); }
        return results;
    }

    private static void authorize() {
        if (!FeatureManagement.checkPermission('P05_Consultar_Tarifas')) { throw error('ACCESS_DENIED'); }
    }
    private static void ensureReadAccess() {
        if (!ConsultaTarifa__c.SObjectType.getDescribe().isAccessible()) { throw error('ACCESS_DENIED'); }
        Map<String, Schema.SObjectField> fields = ConsultaTarifa__c.SObjectType.getDescribe().fields.getMap();
        for (String field : READ_FIELDS.split(',')) {
            if (!fields.get(field).getDescribe().isAccessible()) { throw error('ACCESS_DENIED'); }
        }
    }
    private static ServicioException error(String category) {
        return new ServicioException(category);
    }

    // Única entrada del trigger. No permite establecer ni conceder autorización.
    public static void validarIntegridad() {
        if (!Trigger.isExecuting) { throw error('INTEGRITY_CONTEXT_REQUIRED'); }
        List<ConsultaTarifa__c> rows = (List<ConsultaTarifa__c>) (Trigger.isDelete ? Trigger.old : Trigger.new);
        ConsultaTarifa__c expected = pendingInsert;
        pendingInsert = null; // Un solo uso, incluso frente a invocaciones recursivas.
        Boolean allowed = Trigger.isBefore && Trigger.isInsert && rows.size() == 1 && expected != null;
        for (ConsultaTarifa__c row : rows) {
            Boolean matches = allowed && row.OwnerId == UserInfo.getUserId() && row.OwnerId == expected.OwnerId;
            if (matches) {
                for (String field : SNAPSHOT_FIELDS) {
                    Object actual = row.get(field), wanted = expected.get(field);
                    if (actual instanceof String && wanted instanceof String) {
                        matches = ((String) actual).equals((String) wanted);
                    } else {
                        matches = actual == wanted;
                    }
                    if (!matches) { break; }
                }
            }
            if (!matches) { row.addError('P05_INTEGRITY: la instantánea solo puede crearse desde el servicio y no puede modificarse ni borrarse.'); }
        }
    }
}
