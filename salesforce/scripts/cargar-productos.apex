// Carga administrativa repetible. Nunca ejecutar en la transacción del callout.
Map<String,String> expected = new Map<String,String>{
    'PROD-001' => 'Kit de conexión de demostración',
    'PROD-002' => 'Módulo de control de demostración',
    'PROD-003' => 'Conector auxiliar de demostración'
};
Set<String> codes = expected.keySet();
Set<String> names = new Set<String>(expected.values());
List<Product2> existing = [SELECT Id,Name,IsActive,CodigoProveedor__c FROM Product2
    WHERE CodigoProveedor__c IN :codes OR Name IN :names WITH USER_MODE];
Set<String> found = new Set<String>();
for (Product2 product : existing) {
    System.assert(expected.containsKey(product.CodigoProveedor__c) &&
        product.Name.equals(expected.get(product.CodigoProveedor__c)) && product.IsActive,
        'Carga detenida: existe un producto incompatible. Revisar sin sobrescribirlo.');
    found.add(product.CodigoProveedor__c);
}
List<Product2> missing = new List<Product2>();
for (String code : codes) {
    if (!found.contains(code)) {
        missing.add(new Product2(Name=expected.get(code),CodigoProveedor__c=code,IsActive=true));
    }
}
if (!missing.isEmpty()) { insert as user missing; }
System.debug(LoggingLevel.INFO, JSON.serialize(new Map<String,Object>{
    'operation'=>'product-load', 'created'=>missing.size(),'reused'=>found.size()
}));
