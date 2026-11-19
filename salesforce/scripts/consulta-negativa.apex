// Transacción separada: producto ficticio específico, sin modificar el catálogo normal.
Product2 product = [SELECT Id FROM Product2 WHERE CodigoProveedor__c='PROD-999' WITH USER_MODE LIMIT 1];
Id owner = UserInfo.getUserId();
Integer beforeCount=[SELECT COUNT() FROM ConsultaTarifa__c WHERE OwnerId=:owner WITH USER_MODE];
Boolean rejected=false;
String requestId;
try {
    P05TarifasServicio.consultarYGuardar(product.Id,1);
} catch (P05ConsultaTarifa.ConsultaException ex) {
    System.assert(ex.getMessage().startsWith('PRODUCT_NOT_FOUND (requestId='));
    requestId=ex.getMessage().substringAfter('requestId=').substringBefore(')');
    rejected=true;
}
Integer afterCount=[SELECT COUNT() FROM ConsultaTarifa__c WHERE OwnerId=:owner WITH USER_MODE];
System.assert(rejected);
System.assertEquals(beforeCount,afterCount);
System.debug(LoggingLevel.INFO,JSON.serialize(new Map<String,Object>{
    'operation'=>'negative','productCode'=>'PROD-999','quantity'=>1,
    'category'=>'PRODUCT_NOT_FOUND','requestId'=>requestId,
    'beforeCount'=>beforeCount,'afterCount'=>afterCount,'newRecords'=>afterCount-beforeCount,
    'callouts'=>Limits.getCallouts()
}));
