// Una llamada + inserción por transacción. Ejecutar tras la carga y asignación de permisos.
Product2 product = [SELECT Id FROM Product2 WHERE CodigoProveedor__c='PROD-001' WITH USER_MODE LIMIT 1];
P05TarifasServicio.Detalle result = P05TarifasServicio.consultarYGuardar(product.Id,3);
ConsultaTarifa__c record = result.registro;
System.assertEquals(59.70,record.Total__c);
System.assertEquals(UserInfo.getUserId(),record.OwnerId);
System.debug(LoggingLevel.INFO,JSON.serialize(new Map<String,Object>{
    'operation'=>'save','reference'=>record.Name,'productCode'=>record.CodigoProveedor__c,
    'productName'=>record.NombreProducto__c,'quantity'=>record.Cantidad__c,
    'unitPrice'=>record.PrecioUnitario__c,'totalPrice'=>record.Total__c,'currency'=>record.Moneda__c,
    'requestId'=>record.RequestId__c,'quoteId'=>record.QuoteId__c,'issuedAt'=>record.EmitidaEn__c,
    'receivedAt'=>record.RecibidaEn__c,'validUntil'=>record.CaducaEn__c,
    'schemaVersion'=>record.SchemaVersion__c,'tariffVersion'=>record.TariffVersion__c,
    'persisted'=>record.Id!=null,'ownedByCaller'=>record.OwnerId==UserInfo.getUserId(),
    'callouts'=>Limits.getCallouts()
}));
