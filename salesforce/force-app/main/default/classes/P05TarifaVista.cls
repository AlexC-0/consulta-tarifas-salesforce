public class P05TarifaVista {
    @AuraEnabled public Id recordId {get;set;}
    @AuraEnabled public String reference {get;set;}
    @AuraEnabled public String productName {get;set;}
    @AuraEnabled public String productCode {get;set;}
    @AuraEnabled public Decimal quantity {get;set;}
    @AuraEnabled public Decimal unitPrice {get;set;}
    @AuraEnabled public Decimal totalPrice {get;set;}
    @AuraEnabled public String currencyCode {get;set;}
    @AuraEnabled public Datetime createdAt {get;set;}
    @AuraEnabled public Datetime issuedAt {get;set;}
    @AuraEnabled public Datetime receivedAt {get;set;}
    @AuraEnabled public Datetime validUntil {get;set;}
    @AuraEnabled public String requestId {get;set;}
    @AuraEnabled public String notice {get;set;}
    public P05TarifaVista(P05TarifasServicio.Detalle source) {
        ConsultaTarifa__c row=source.registro;
        recordId=row.Id;reference=row.Name;productName=row.NombreProducto__c;
        productCode=row.CodigoProveedor__c;quantity=row.Cantidad__c;
        unitPrice=row.PrecioUnitario__c;totalPrice=row.Total__c;currencyCode=row.Moneda__c;
        createdAt=row.CreatedDate;issuedAt=row.EmitidaEn__c;receivedAt=row.RecibidaEn__c;
        validUntil=row.CaducaEn__c;requestId=row.RequestId__c;notice=source.aviso;
    }
}
