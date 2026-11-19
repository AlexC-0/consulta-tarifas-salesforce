@IsTest
private class P05TarifasControladorTest {
    private class Mock implements HttpCalloutMock {
        Integer status=200;
        Integer expectedDml=Limits.getDmlStatements();
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals(expectedDml,Limits.getDmlStatements());
            Map<String,Object> input=(Map<String,Object>)JSON.deserializeUntyped(request.getBody());
            Datetime issued=Datetime.now().addSeconds(-2);
            HttpResponse response=new HttpResponse();response.setStatusCode(status);
            response.setHeader('Content-Type','application/json');
            response.setBody(JSON.serialize(new Map<String,Object>{
                'schemaVersion'=>'1','requestId'=>request.getHeader('X-Request-Id'),'quoteId'=>UUID.randomUUID().toString(),
                'productCode'=>input.get('productCode'),'quantity'=>input.get('quantity'),'currency'=>'EUR',
                'unitPrice'=>'19.90','totalPrice'=>String.valueOf((19.90*Decimal.valueOf(String.valueOf(input.get('quantity')))).setScale(2)),
                'issuedAt'=>iso(issued),'validUntil'=>iso(issued.addHours(24)),'tariffVersion'=>'demo-1'
            }));return response;
        }
    }
    private static String iso(Datetime d){return d.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');}
    private class Seed implements Queueable,Database.AllowsCallouts {
        public void execute(QueueableContext c){
            Product2 p=[SELECT Id FROM Product2 WHERE CodigoProveedor__c='PROD-001' WITH USER_MODE LIMIT 1];
            P05TarifasControlador.consultarYGuardar(p.Id,3);
        }
    }
    @TestSetup static void setupData(){
        Id profile=[SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce' WITH SYSTEM_MODE LIMIT 1].Id;
        List<User> users=new List<User>();
        for(String alias:new List<String>{'p05ui1','p05ui2','p05uino','p05uifn'}){
            users.add(new User(Alias=alias,LastName='Prueba UI '+alias,Username=UUID.randomUUID().toString()+'@example.invalid',
                Email=alias+'@example.invalid',ProfileId=profile,TimeZoneSidKey='Europe/Madrid',LocaleSidKey='es_ES',
                EmailEncodingKey='UTF-8',LanguageLocaleKey='es'));
        }
        insert as system users;
        Map<String,Id> sets=new Map<String,Id>();
        for(PermissionSet p:[SELECT Id,Name FROM PermissionSet WHERE Name IN ('P05_Datos_Tarifas','P05_Consultar_Tarifas','P05_Conexion_Proveedor') WITH SYSTEM_MODE]){sets.put(p.Name,p.Id);}
        List<PermissionSetAssignment> grants=new List<PermissionSetAssignment>();
        for(User u:users){
            if(u.Alias=='p05uino')continue;
            for(String name:sets.keySet()){
                if(u.Alias!='p05uifn'||name=='P05_Consultar_Tarifas'){grants.add(new PermissionSetAssignment(AssigneeId=u.Id,PermissionSetId=sets.get(name)));}
            }
        }
        insert as system grants;
        System.runAs(new User(Id=UserInfo.getUserId())){
            insert as system new List<Product2>{
                new Product2(Name='A Producto',CodigoProveedor__c='PROD-001',IsActive=true),
                new Product2(Name='B Producto',CodigoProveedor__c='PROD-002',IsActive=true),
                new Product2(Name='C Producto',CodigoProveedor__c='PROD-123',IsActive=true),
                new Product2(Name='Inactivo',CodigoProveedor__c='PROD-003',IsActive=false),
                new Product2(Name='Sin código',IsActive=true),
                new Product2(Name='Fixture negativo',CodigoProveedor__c='PROD-999',IsActive=true)
            };
        }
        Mock mock=new Mock();mock.expectedDml=0;Test.setMock(HttpCalloutMock.class,mock);
        Test.startTest();
        System.runAs(users[0]){System.enqueueJob(new Seed());}
        System.runAs(users[1]){System.enqueueJob(new Seed());}
        Test.stopTest();
    }
    private static User actor(String alias){return [SELECT Id FROM User WHERE Alias=:alias WITH SYSTEM_MODE LIMIT 1];}
    private static Map<String,Object> payload(AuraHandledException ex){return (Map<String,Object>)JSON.deserializeUntyped(ex.getMessage());}
    @IsTest static void productsAreFilteredOrderedAndMinimal(){
        System.runAs(actor('p05ui1')){
            List<P05ProductoOpcion> products=P05TarifasControlador.listarProductos();
            System.assertEquals(3,products.size());System.assertEquals('PROD-001',products[0].code);
            System.assertEquals('PROD-002',products[1].code);System.assertEquals('PROD-123',products[2].code);
            Map<String,Object> json=(Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(products[0]));
            System.assertEquals(new Set<String>{'productId','name','code'},json.keySet());
            System.assertEquals(0,Limits.getCallouts());
        }
    }
    @IsTest static void rejectsFunctionalAndProductAccess(){
        for(String alias:new List<String>{'p05uino','p05uifn'}){
            System.runAs(actor(alias)){
                try{P05TarifasControlador.listarProductos();System.assert(false);}
                catch(AuraHandledException ex){System.assertEquals('ACCESS_DENIED',payload(ex).get('code'));}
                System.assertEquals(0,Limits.getCallouts());
            }
        }
    }
    @IsTest static void saveDelegatesAndReturnsTopLevelDto(){
        Id productId=[SELECT Id FROM Product2 WHERE CodigoProveedor__c='PROD-001' WITH SYSTEM_MODE LIMIT 1].Id;
        System.runAs(actor('p05ui1')){
            Test.setMock(HttpCalloutMock.class,new Mock());
            P05TarifaVista saved=P05TarifasControlador.consultarYGuardar(productId,3);
            System.assertNotEquals(null,saved.recordId);System.assert(saved.reference.startsWith('P05-'));
            System.assertEquals(59.70,saved.totalPrice);System.assertEquals('EUR',saved.currencyCode);
            System.assertEquals('PROD-001',saved.productCode);System.assertEquals(3,saved.quantity);
            System.assertEquals(86400000,saved.validUntil.getTime()-saved.issuedAt.getTime());
            System.assert(saved.serverNow >= saved.receivedAt && saved.serverNow <= Datetime.now());
            Map<String,Object> json=(Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(saved));
            System.assert(!json.containsKey('registro'));System.assert(!json.containsKey('OwnerId'));
            System.assert(!json.containsKey('vigente'));System.assert(json.containsKey('validUntil'));
            System.assertEquals(1,Limits.getCallouts());
        }
    }
    @IsTest static void invalidInputAndUnauthorizedSaveNeverCallProvider(){
        Id id=[SELECT Id FROM Product2 WHERE CodigoProveedor__c='PROD-001' WITH SYSTEM_MODE LIMIT 1].Id;
        System.runAs(actor('p05ui1')){
            try{P05TarifasControlador.consultarYGuardar(id,1.5);System.assert(false);}
            catch(AuraHandledException ex){System.assertEquals('INVALID_REQUEST',payload(ex).get('code'));}
            System.assertEquals(0,Limits.getCallouts());
        }
        System.runAs(actor('p05uino')){
            try{P05TarifasControlador.consultarYGuardar(id,1);System.assert(false);}
            catch(AuraHandledException ex){System.assertEquals('ACCESS_DENIED',payload(ex).get('code'));}
            System.assertEquals(0,Limits.getCallouts());
        }
    }
    @IsTest static void providerFailureIsTranslatedWithoutPersisting(){
        Id id=[SELECT Id FROM Product2 WHERE CodigoProveedor__c='PROD-999' WITH SYSTEM_MODE LIMIT 1].Id;
        System.runAs(actor('p05ui1')){
            Integer before=[SELECT COUNT() FROM ConsultaTarifa__c WITH USER_MODE];
            Mock mock=new Mock();mock.status=404;Test.setMock(HttpCalloutMock.class,mock);
            try{P05TarifasControlador.consultarYGuardar(id,1);System.assert(false);}
            catch(AuraHandledException ex){
                Map<String,Object> p=payload(ex);System.assertEquals('PRODUCT_NOT_FOUND',p.get('code'));
                System.assertEquals(36,((String)p.get('requestId')).length());
            }
            System.assertEquals(before,[SELECT COUNT() FROM ConsultaTarifa__c WITH USER_MODE]);
        }
    }
    @IsTest static void readsOwnHistoryAndDeniesForeignDetailWithoutCallouts(){
        Id other;System.runAs(actor('p05ui2')){other=P05TarifasControlador.listarPropias()[0].recordId;}
        System.runAs(actor('p05ui1')){
            List<P05TarifaVista> rows=P05TarifasControlador.listarPropias();System.assertEquals(1,rows.size());
            System.assertEquals(rows[0].recordId,P05TarifasControlador.obtener(rows[0].recordId).recordId);
            try{P05TarifasControlador.obtener(other);System.assert(false);}
            catch(AuraHandledException ex){System.assertEquals('NOT_FOUND',payload(ex).get('code'));}
            System.assertEquals(0,Limits.getCallouts());
        }
        System.runAs(actor('p05uino')){
            try{P05TarifasControlador.listarPropias();System.assert(false);}
            catch(AuraHandledException ex){System.assertEquals('ACCESS_DENIED',payload(ex).get('code'));}
            try{P05TarifasControlador.obtener(other);System.assert(false);}
            catch(AuraHandledException ex){System.assertEquals('ACCESS_DENIED',payload(ex).get('code'));}
        }
    }
    @IsTest static void allKnownErrorsAreSafeAndUnknownDetailsAreHidden(){
        String requestId=UUID.randomUUID().toString();
        for(String code:new List<String>{'INVALID_REQUEST','PRODUCT_UNAVAILABLE','PRODUCT_NOT_FOUND','ACCESS_DENIED',
            'UNAUTHORIZED','CONNECTION_ERROR','PROVIDER_UNAVAILABLE','INTERNAL_ERROR','RATE_LIMITED','HTTP_ERROR',
            'TIMEOUT','INVALID_RESPONSE','SAVE_FAILED','NOT_FOUND'}){
            Exception source=new P05ConsultaTarifa.ConsultaException(code+' (requestId='+requestId+')');
            Map<String,Object> p=payload(P05TarifasControlador.safeError(source));
            System.assertEquals(code,p.get('code'));System.assertEquals(requestId,p.get('requestId'));
            System.assertEquals('P05',p.get('kind'));System.assertNotEquals(code,p.get('message'));
        }
        Map<String,Object> unknown=payload(P05TarifasControlador.safeError(new P05TarifasServicio.ServicioException('private token stack')));
        System.assertEquals('UNEXPECTED',unknown.get('code'));
        System.assert(!JSON.serialize(unknown).contains('private'));
        System.assertEquals(null,unknown.get('requestId'));
        Map<String,Object> generic=payload(P05TarifasControlador.safeError(new QueryException('private database details')));
        System.assertEquals('UNEXPECTED',generic.get('code'));
    }
    @IsTest static void serverTimeIsAuthorizedAndNeverCallsProvider(){
        System.runAs(actor('p05ui1')){
            Datetime before=Datetime.now();
            Datetime reference=P05TarifasControlador.obtenerHora();
            System.assert(reference>=before && reference<=Datetime.now());
            P05TarifaVista historical=P05TarifasControlador.listarPropias()[0];
            System.assert(historical.serverNow>=before);
            System.assertEquals(0,Limits.getCallouts());
        }
        System.runAs(actor('p05uino')){
            try{P05TarifasControlador.obtenerHora();System.assert(false);}
            catch(AuraHandledException ex){System.assertEquals('ACCESS_DENIED',payload(ex).get('code'));}
        }
    }
}
