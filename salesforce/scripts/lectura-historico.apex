// Otra transacción; funciona también con proveedor y túnel detenidos.
List<P05TarifasServicio.Detalle> history=P05TarifasServicio.listarPropias(10);
System.assert(!history.isEmpty(),'Se requiere una consulta guardada previamente.');
P05TarifasServicio.Detalle detail=P05TarifasServicio.obtener(history[0].registro.Id);
ConsultaTarifa__c record=detail.registro;
System.assertEquals(0,Limits.getCallouts());
System.debug(LoggingLevel.INFO,JSON.serialize(new Map<String,Object>{
    'operation'=>'read','reference'=>record.Name,'requestId'=>record.RequestId__c,
    'productCode'=>record.CodigoProveedor__c,'productName'=>record.NombreProducto__c,
    'quantity'=>record.Cantidad__c,'totalPrice'=>record.Total__c,'currency'=>record.Moneda__c,
    'issuedAt'=>record.EmitidaEn__c,'receivedAt'=>record.RecibidaEn__c,'validUntil'=>record.CaducaEn__c,
    'validNow'=>detail.vigente,'notice'=>detail.aviso,
    'historyCount'=>history.size(),'callouts'=>Limits.getCallouts()
}));
