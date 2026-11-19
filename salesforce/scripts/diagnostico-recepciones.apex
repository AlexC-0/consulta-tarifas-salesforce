// Sonda sin DML: sustituir EXPECTED_STATUS en una copia local, no en este archivo.
String expectedText='EXPECTED_STATUS';
System.assertNotEquals('EXPECTED_'+'STATUS',expectedText,'Preparar el estado esperado en una copia local.');
Integer expectedStatus=Integer.valueOf(expectedText);
Map<Integer,String> categories=new Map<Integer,String>{200=>'OK',401=>'UNAUTHORIZED',429=>'RATE_LIMITED',503=>'PROVIDER_UNAVAILABLE'};
System.assert(categories.containsKey(expectedStatus));
String query='SELECT Id,Name,OwnerId,CreatedById,CreatedDate,Producto__c,NombreProducto__c,CodigoProveedor__c,'+
    'Cantidad__c,PrecioUnitario__c,Total__c,Moneda__c,EmitidaEn__c,RecibidaEn__c,CaducaEn__c,'+
    'RequestId__c,QuoteId__c,SchemaVersion__c,TariffVersion__c FROM ConsultaTarifa__c ORDER BY Id';
List<SObject> beforeRows=Database.query(query);
String beforeHash=EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256',Blob.valueOf(JSON.serialize(beforeRows))));
Integer calls=Limits.getCallouts(),dml=Limits.getDmlStatements();
Datetime started=Datetime.now();
String category,requestId;
try {
    P05ConsultaTarifa.Tarifa result=P05ConsultaTarifa.consultarDemo();
    category='OK';requestId=result.requestId;
} catch(P05ConsultaTarifa.ConsultaException ex) {
    category=ex.getMessage().substringBefore(' (requestId=');
    Matcher correlation=Pattern.compile('requestId=([a-fA-F0-9-]{36})').matcher(ex.getMessage());
    System.assert(correlation.find());requestId=correlation.group(1);
}
Long elapsedMs=Datetime.now().getTime()-started.getTime();
List<SObject> afterRows=Database.query(query);
String afterHash=EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256',Blob.valueOf(JSON.serialize(afterRows))));
System.assertEquals(categories.get(expectedStatus),category);
System.assertEquals(1,Limits.getCallouts()-calls);
System.assertEquals(dml,Limits.getDmlStatements());
System.assertEquals(beforeHash,afterHash);
System.debug(LoggingLevel.INFO,JSON.serialize(new Map<String,Object>{
    'operations'=>1,'callouts'=>Limits.getCallouts()-calls,'requestId'=>requestId,
    'category'=>category,'status'=>expectedStatus,'elapsedMs'=>elapsedMs,
    'beforeCount'=>beforeRows.size(),'afterCount'=>afterRows.size(),'historyUnchanged'=>beforeHash==afterHash,
    'dmlStatements'=>Limits.getDmlStatements()-dml
}));
