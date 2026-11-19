// Sonda administrativa complementaria. EXPECTED_CATEGORY se sustituye en copia local.
String expectedCategory='EXPECTED_CATEGORY';
System.assertNotEquals('EXPECTED_'+'CATEGORY',expectedCategory,'Preparar una copia local con la categoría esperada.');
List<ConsultaTarifa__c> beforeRows=[SELECT Id,Name,OwnerId,Producto__c,CodigoProveedor__c,
    NombreProducto__c,Cantidad__c,PrecioUnitario__c,Total__c,Moneda__c,EmitidaEn__c,
    RecibidaEn__c,CaducaEn__c,RequestId__c,QuoteId__c,TariffVersion__c,SchemaVersion__c
    FROM ConsultaTarifa__c ORDER BY Id];
String beforeHash=EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256',Blob.valueOf(JSON.serialize(beforeRows))));
Product2 product=[SELECT Id FROM Product2 WHERE CodigoProveedor__c='PROD-001' WITH USER_MODE LIMIT 1];
Integer calls=Limits.getCallouts();
Map<String,Object> payload;
try {
    P05TarifasServicio.consultarYGuardar(product.Id,3);
    System.assert(false,'Se esperaba un rechazo; la transacción debe revertirse.');
} catch(P05ConsultaTarifa.ConsultaException ex) {
    String category=ex.getMessage().substringBefore(' (requestId=');
    Matcher correlation=Pattern.compile('requestId=([a-fA-F0-9-]{36})').matcher(ex.getMessage());
    System.assert(correlation.find());
    payload=new Map<String,Object>{'code'=>category,'requestId'=>correlation.group(1)};
}
List<ConsultaTarifa__c> afterRows=[SELECT Id,Name,OwnerId,Producto__c,CodigoProveedor__c,
    NombreProducto__c,Cantidad__c,PrecioUnitario__c,Total__c,Moneda__c,EmitidaEn__c,
    RecibidaEn__c,CaducaEn__c,RequestId__c,QuoteId__c,TariffVersion__c,SchemaVersion__c
    FROM ConsultaTarifa__c ORDER BY Id];
String afterHash=EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256',Blob.valueOf(JSON.serialize(afterRows))));
System.assertEquals(expectedCategory,payload.get('code'));
System.assertEquals(beforeHash,afterHash);
System.assertEquals(1,Limits.getCallouts()-calls);
System.assertEquals(36,((String)payload.get('requestId')).length());
System.debug(LoggingLevel.INFO,JSON.serialize(new Map<String,Object>{
    'operation'=>'failure-check','category'=>payload.get('code'),
    'requestId'=>payload.get('requestId'),'callouts'=>Limits.getCallouts()-calls,
    'beforeCount'=>beforeRows.size(),'afterCount'=>afterRows.size(),'historyUnchanged'=>beforeHash==afterHash,
    'newSnapshots'=>afterRows.size()-beforeRows.size()
}));
