public with sharing class P05TarifasControlador {
    @AuraEnabled
    public static List<P05ProductoOpcion> listarProductos() {
        try {
            if (!FeatureManagement.checkPermission('P05_Consultar_Tarifas') ||
                !Product2.SObjectType.getDescribe().isAccessible() ||
                !Product2.Name.getDescribe().isAccessible() ||
                !Product2.IsActive.getDescribe().isAccessible() ||
                !Product2.CodigoProveedor__c.getDescribe().isAccessible()) {
                throw new P05TarifasServicio.ServicioException('ACCESS_DENIED');
            }
            List<P05ProductoOpcion> result=new List<P05ProductoOpcion>();
            // PROD-999 es exclusivamente el fixture negativo de demostración.
            for(Product2 product:[SELECT Id,Name,CodigoProveedor__c FROM Product2
                WHERE IsActive=true AND CodigoProveedor__c!=null AND CodigoProveedor__c!='PROD-999'
                WITH USER_MODE ORDER BY Name,Id LIMIT 200]) {
                if(Pattern.matches('^PROD-[0-9]{3}$',product.CodigoProveedor__c)) {
                    result.add(new P05ProductoOpcion(product));
                }
            }
            return result;
        } catch(Exception ex) {throw safeError(ex);}
    }
    @AuraEnabled
    public static P05TarifaVista consultarYGuardar(Id productId,Decimal quantity) {
        try {return new P05TarifaVista(P05TarifasServicio.consultarYGuardar(productId,quantity));}
        catch(Exception ex) {throw safeError(ex);}
    }
    @AuraEnabled
    public static List<P05TarifaVista> listarPropias() {
        try {
            List<P05TarifaVista> result=new List<P05TarifaVista>();
            for(P05TarifasServicio.Detalle item:P05TarifasServicio.listarPropias(50)) {
                result.add(new P05TarifaVista(item));
            }
            return result;
        } catch(Exception ex) {throw safeError(ex);}
    }
    @AuraEnabled
    public static P05TarifaVista obtener(Id recordId) {
        try {return new P05TarifaVista(P05TarifasServicio.obtener(recordId));}
        catch(Exception ex) {throw safeError(ex);}
    }
    @TestVisible private static AuraHandledException safeError(Exception ex) {
        Map<String,String> messages=new Map<String,String>{
            'INVALID_REQUEST'=>'Revisa el producto y la cantidad: debe ser un entero entre 1 y 10.000.',
            'PRODUCT_UNAVAILABLE'=>'El producto no está disponible en Salesforce.',
            'PRODUCT_NOT_FOUND'=>'El proveedor no dispone de una tarifa para este producto.',
            'ACCESS_DENIED'=>'No tienes permisos suficientes para realizar esta operación.',
            'UNAUTHORIZED'=>'No se ha podido autenticar la conexión con el proveedor. Contacta con el responsable.',
            'CONNECTION_ERROR'=>'No se ha podido conectar con el proveedor. Revisa la conexión con el responsable.',
            'PROVIDER_UNAVAILABLE'=>'El proveedor no está disponible en este momento.',
            'INTERNAL_ERROR'=>'El proveedor no ha podido procesar la consulta.',
            'RATE_LIMITED'=>'El proveedor ha limitado las consultas. Inténtalo más tarde.',
            'HTTP_ERROR'=>'El proveedor no ha respondido correctamente.',
            'TIMEOUT'=>'El proveedor ha tardado demasiado en responder.',
            'INVALID_RESPONSE'=>'La respuesta del proveedor no es válida. No se ha guardado ninguna tarifa.',
            'SAVE_FAILED'=>'No se ha podido guardar la consulta. No se ha confirmado ningún registro nuevo.',
            'NOT_FOUND'=>'La consulta histórica no está disponible para tu usuario.',
            'UNEXPECTED'=>'No se ha podido confirmar el resultado. Revisa Mis consultas antes de volver a intentarlo.'
        };
        String code='UNEXPECTED',requestId;
        if(ex instanceof P05TarifasServicio.ServicioException || ex instanceof P05ConsultaTarifa.ConsultaException) {
            String candidate=ex.getMessage().substringBefore(' (requestId=');
            if(messages.containsKey(candidate)){code=candidate;}
            Matcher match=Pattern.compile('requestId=([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})').matcher(ex.getMessage());
            if(match.find()){requestId=match.group(1);}
        }
        String payload=JSON.serialize(new Map<String,Object>{
            'kind'=>'P05','code'=>code,'message'=>messages.get(code),'requestId'=>requestId
        });
        AuraHandledException result=new AuraHandledException(payload);
        result.setMessage(payload);
        return result;
    }
}
