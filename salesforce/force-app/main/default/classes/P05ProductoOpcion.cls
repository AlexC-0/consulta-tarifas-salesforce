public class P05ProductoOpcion {
    @AuraEnabled public Id productId {get;set;}
    @AuraEnabled public String name {get;set;}
    @AuraEnabled public String code {get;set;}
    public P05ProductoOpcion(Product2 product) {
        productId=product.Id;name=product.Name;code=product.CodigoProveedor__c;
    }
}
