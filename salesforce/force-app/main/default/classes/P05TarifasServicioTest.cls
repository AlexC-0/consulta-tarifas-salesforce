@IsTest
private class P05TarifasServicioTest {
    private class ProviderMock implements HttpCalloutMock {
        Integer status = 200;
        Integer expectedDml = Limits.getDmlStatements();
        String unitPrice = '19.90';
        Boolean timeout = false;
        Boolean invalidResponse = false;
        Boolean deleteProduct = false;
        Boolean expiresSoon = false;
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals(expectedDml, Limits.getDmlStatements(), 'El servicio no puede añadir DML antes del callout, incluido savepoint.');
            Map<String, Object> input = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
            Decimal quantity = Decimal.valueOf(String.valueOf(input.get('quantity')));
            if (timeout) { throw new CalloutException('Read timed out'); }
            if (deleteProduct) {
                // Solo fixture de prueba: fuerza un fallo real de FK después del callout.
                Product2 product = [SELECT Id,CreatedById FROM Product2 WHERE CodigoProveedor__c = 'PROD-005' WITH SYSTEM_MODE LIMIT 1];
                System.runAs(new User(Id=product.CreatedById)) { delete as system product; }
            }
            Datetime issued = Datetime.now().addSeconds(expiresSoon ? -86399 : -2);
            HttpResponse response = new HttpResponse();
            response.setStatusCode(status);
            response.setHeader('Content-Type', 'application/json');
            response.setBody(JSON.serialize(new Map<String, Object>{
                'schemaVersion' => '1', 'requestId' => request.getHeader('X-Request-Id'),
                'quoteId' => UUID.randomUUID().toString(), 'productCode' => input.get('productCode'),
                'quantity' => quantity, 'currency' => 'EUR', 'unitPrice' => unitPrice,
                'totalPrice' => invalidResponse ? '0.00' : String.valueOf((Decimal.valueOf(unitPrice) * quantity).setScale(2)),
                'issuedAt' => iso(issued), 'validUntil' => iso(issued.addHours(24)), 'tariffVersion' => 'tarifa-fase-3'
            }));
            return response;
        }
    }
    // Datos de referencia creados por el servicio en transacciones separadas.
    // No existe bypass de integridad ni rama Test.isRunningTest en producción.
    private class SeedSnapshot implements Queueable, Database.AllowsCallouts {
        public void execute(QueueableContext context) {
            Product2 product = [SELECT Id FROM Product2 WHERE CodigoProveedor__c = 'PROD-001' WITH USER_MODE LIMIT 1];
            P05TarifasServicio.consultarYGuardar(product.Id, 3);
        }
    }
    @TestSetup static void setupData() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' WITH SYSTEM_MODE LIMIT 1].Id;
        List<User> users = new List<User>();
        for (String alias : new List<String>{'p05a','p05b','p05none','p05fun','p05data','p05fls','p05prod'}) {
            users.add(new User(Alias=alias, LastName='P05 prueba '+alias,
                Email=alias+'@example.invalid', Username=UUID.randomUUID().toString()+'@example.invalid',
                ProfileId=profileId, TimeZoneSidKey='Europe/Madrid', LocaleSidKey='es_ES',
                EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US'));
        }
        insert as system users;
        Map<String, Id> sets = new Map<String, Id>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN
            ('P05_Consultar_Tarifas','P05_Datos_Tarifas','P05_Conexion_Proveedor') WITH SYSTEM_MODE]) {
            sets.put(ps.Name, ps.Id);
        }
        PermissionSet partial = new PermissionSet(Name='P05_Test_WithoutTotalWrite', Label='P05 test sin escritura total');
        insert as system partial;
        insert as system new List<ObjectPermissions>{
            new ObjectPermissions(ParentId=partial.Id,SobjectType='Product2',PermissionsRead=true),
            new ObjectPermissions(ParentId=partial.Id,SobjectType='ConsultaTarifa__c',PermissionsRead=true,PermissionsCreate=true)
        };
        List<FieldPermissions> fieldGrants = new List<FieldPermissions>{
            new FieldPermissions(ParentId=partial.Id,SobjectType='Product2',Field='Product2.CodigoProveedor__c',PermissionsRead=true)
        };
        for (String field : new List<String>{'Producto__c','NombreProducto__c','CodigoProveedor__c','Moneda__c','RequestId__c','QuoteId__c','TariffVersion__c','SchemaVersion__c','Cantidad__c','PrecioUnitario__c','Total__c','EmitidaEn__c','RecibidaEn__c','CaducaEn__c'}) {
            fieldGrants.add(new FieldPermissions(ParentId=partial.Id,SobjectType='ConsultaTarifa__c',
                Field='ConsultaTarifa__c.'+field,PermissionsRead=true,PermissionsEdit=field!='Total__c'));
        }
        insert as system fieldGrants;
        PermissionSet noProduct=new PermissionSet(Name='P05_Test_NoProduct',Label='P05 test sin producto');
        insert as system noProduct;
        insert as system new ObjectPermissions(ParentId=noProduct.Id,SobjectType='ConsultaTarifa__c',PermissionsRead=true,PermissionsCreate=true);
        List<FieldPermissions> noProductFields=new List<FieldPermissions>();
        for(FieldPermissions original:fieldGrants){
            if(original.SobjectType=='ConsultaTarifa__c'){
                noProductFields.add(new FieldPermissions(ParentId=noProduct.Id,SobjectType='ConsultaTarifa__c',Field=original.Field,PermissionsRead=true,PermissionsEdit=true));
            }
        }
        insert as system noProductFields;
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (User u : users) {
            if (u.Alias != 'p05none' && u.Alias != 'p05data') {
                assignments.add(new PermissionSetAssignment(AssigneeId=u.Id,PermissionSetId=sets.get('P05_Consultar_Tarifas')));
                assignments.add(new PermissionSetAssignment(AssigneeId=u.Id,PermissionSetId=sets.get('P05_Conexion_Proveedor')));
            }
            if (new Set<String>{'p05a','p05b','p05data'}.contains(u.Alias)) {
                assignments.add(new PermissionSetAssignment(AssigneeId=u.Id,PermissionSetId=sets.get('P05_Datos_Tarifas')));
            }
            if (u.Alias == 'p05prod') {
                assignments.add(new PermissionSetAssignment(AssigneeId=u.Id,PermissionSetId=noProduct.Id));
            }
            if (u.Alias == 'p05fls') {
                assignments.add(new PermissionSetAssignment(AssigneeId=u.Id,PermissionSetId=partial.Id));
            }
        }
        insert as system assignments;
        System.runAs(new User(Id=UserInfo.getUserId())) {
            insert as system new List<Product2>{
                new Product2(Name='Producto ficticio uno',CodigoProveedor__c='PROD-001',IsActive=true),
                new Product2(Name='N'.repeat(255),CodigoProveedor__c='PROD-002',IsActive=true),
                new Product2(Name='Producto inactivo',CodigoProveedor__c='PROD-003',IsActive=false),
                new Product2(Name='Producto sin código',IsActive=true),
                new Product2(Name='Producto para fallo FK',CodigoProveedor__c='PROD-005',IsActive=true)
            };
        }
        ProviderMock seedMock=new ProviderMock();seedMock.expectedDml=0;
        Test.setMock(HttpCalloutMock.class, seedMock);
        Test.startTest();
        System.runAs(users[0]) { System.enqueueJob(new SeedSnapshot()); }
        System.runAs(users[1]) { System.enqueueJob(new SeedSnapshot()); }
        Test.stopTest();
    }
    private static User actor(String alias) {
        return [SELECT Id FROM User WHERE Alias=:alias WITH SYSTEM_MODE LIMIT 1];
    }
    private static Product2 product(String code) {
        return [SELECT Id, Name, CodigoProveedor__c FROM Product2 WHERE CodigoProveedor__c=:code WITH SYSTEM_MODE LIMIT 1];
    }
    private static Integer countAll() {
        return [SELECT COUNT() FROM ConsultaTarifa__c WITH SYSTEM_MODE];
    }
    private static String iso(Datetime timeValue) { return timeValue.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''); }
    private static void rejectedBeforeCallout(Id productId, Decimal quantity, String category) {
        Integer calls=Limits.getCallouts(), before=countAll();
        try {
            P05TarifasServicio.consultarYGuardar(productId, quantity);
            System.assert(false, 'Debe rechazar la entrada o permisos.');
        } catch (P05TarifasServicio.ServicioException ex) { System.assertEquals(category,ex.getMessage()); }
        System.assertEquals(calls,Limits.getCallouts());
        System.assertEquals(before,countAll());
    }
    @IsTest static void savesAllFieldsAsCurrentUser() {
        Product2 p=product('PROD-001');
        User u=actor('p05a');
        System.runAs(u) {
            System.assert(FeatureManagement.checkPermission('P05_Consultar_Tarifas'));
            System.assert(ConsultaTarifa__c.SObjectType.getDescribe().isCreateable());
            System.assert(!ConsultaTarifa__c.SObjectType.getDescribe().isUpdateable());
            System.assert(!ConsultaTarifa__c.SObjectType.getDescribe().isDeletable());
            Test.setMock(HttpCalloutMock.class,new ProviderMock());
            Datetime before=Datetime.now();
            P05TarifasServicio.Detalle d=P05TarifasServicio.consultarYGuardar(p.Id,3);
            ConsultaTarifa__c r=d.registro;
            System.assertNotEquals(null,r.Id); System.assert(r.Name.startsWith('P05-'));
            System.assertEquals(p.Id,r.Producto__c); System.assertEquals(p.Name,r.NombreProducto__c);
            System.assertEquals('PROD-001',r.CodigoProveedor__c); System.assertEquals(3,r.Cantidad__c);
            System.assertEquals(19.90,r.PrecioUnitario__c); System.assertEquals(59.70,r.Total__c);
            System.assertEquals('EUR',r.Moneda__c); System.assertEquals('1',r.SchemaVersion__c);
            System.assertEquals('tarifa-fase-3',r.TariffVersion__c);
            System.assertEquals(u.Id,r.OwnerId); System.assertEquals(u.Id,r.CreatedById);
            // Los campos DateTime persistidos tienen resolución de segundos.
            System.assert(r.RecibidaEn__c.getTime()/1000>=before.getTime()/1000 && r.RecibidaEn__c<=Datetime.now());
            System.assert(r.EmitidaEn__c<=r.RecibidaEn__c);
            System.assertEquals(86400000,r.CaducaEn__c.getTime()-r.EmitidaEn__c.getTime());
            System.assertEquals(36,r.RequestId__c.length()); System.assertEquals(36,r.QuoteId__c.length());
            System.assert(d.vigente); System.assert(d.aviso.contains('no se actualiza automáticamente'));
            System.assertEquals(1,Limits.getCallouts());
        }
    }
    @IsTest static void savesMaximumAmountAndQuantity() {
        Id id=product('PROD-002').Id;
        System.runAs(actor('p05a')) {
            ProviderMock mock=new ProviderMock();mock.unitPrice='999999.99';
            Test.setMock(HttpCalloutMock.class,mock);
            ConsultaTarifa__c r=P05TarifasServicio.consultarYGuardar(id,10000).registro;
            System.assertEquals(10000,r.Cantidad__c);System.assertEquals(9999999900.00,r.Total__c);System.assertEquals(255,r.NombreProducto__c.length());
        }
    }
    @IsTest static void savesMinimumQuantity() {
        Id id=product('PROD-002').Id;
        System.runAs(actor('p05a')) {
            ProviderMock mock=new ProviderMock();mock.unitPrice='0.01';
            Test.setMock(HttpCalloutMock.class,mock);
            ConsultaTarifa__c r=P05TarifasServicio.consultarYGuardar(id,1).registro;
            System.assertEquals(1,r.Cantidad__c);System.assertEquals(0.01,r.Total__c);
        }
    }
    @IsTest static void rejectsInputsAndUnavailableProducts() {
        Id good=product('PROD-001').Id, inactive=product('PROD-003').Id;
        Id noCode=[SELECT Id FROM Product2 WHERE Name='Producto sin código' WITH SYSTEM_MODE LIMIT 1].Id;
        System.runAs(actor('p05a')) {
            Test.setMock(HttpCalloutMock.class,new ProviderMock());
            rejectedBeforeCallout(null,1,'INVALID_REQUEST');
            rejectedBeforeCallout(UserInfo.getUserId(),1,'INVALID_REQUEST');
            for(Decimal quantity:new List<Decimal>{null,0,-1,1.5,10001}) {
                rejectedBeforeCallout(good,quantity,'INVALID_REQUEST');
            }
            rejectedBeforeCallout(inactive,1,'PRODUCT_UNAVAILABLE');
            rejectedBeforeCallout(noCode,1,'PRODUCT_UNAVAILABLE');
            rejectedBeforeCallout((Id)'01t000000000001',1,'PRODUCT_UNAVAILABLE');
        }
    }
    @IsTest static void rejectsMissingFunctionalObjectAndFieldPermissions() {
        Id id=product('PROD-001').Id;
        for(String alias:new List<String>{'p05none','p05data','p05fun','p05fls','p05prod'}) {
            System.runAs(actor(alias)) {
                Test.setMock(HttpCalloutMock.class,new ProviderMock());
                if(alias=='p05prod') {
                    System.assert(ConsultaTarifa__c.SObjectType.getDescribe().isCreateable());
                    System.assert(!Product2.SObjectType.getDescribe().isAccessible());
                }
                if(alias=='p05fls') {
                    System.assert(ConsultaTarifa__c.SObjectType.getDescribe().isCreateable());
                    System.assert(ConsultaTarifa__c.Total__c.getDescribe().isAccessible());
                    System.assert(!ConsultaTarifa__c.Total__c.getDescribe().isCreateable());
                }
                rejectedBeforeCallout(id,1,'ACCESS_DENIED');
            }
        }
    }
    @IsTest static void providerErrorsCreateNoRows() {
        Id id=product('PROD-001').Id;
        System.runAs(actor('p05a')) {
            Map<String,Integer> statuses = new Map<String,Integer>{'PRODUCT_NOT_FOUND'=>404,'UNAUTHORIZED'=>401,
                'RATE_LIMITED'=>429,'INTERNAL_ERROR'=>500,'PROVIDER_UNAVAILABLE'=>503,'TIMEOUT'=>200,'INVALID_RESPONSE'=>200};
            for(String category:statuses.keySet()) {
                ProviderMock mock=new ProviderMock();
                mock.status=statuses.get(category);
                mock.timeout=category=='TIMEOUT';mock.invalidResponse=category=='INVALID_RESPONSE';
                Test.setMock(HttpCalloutMock.class,mock);
                Integer before=countAll(),calls=Limits.getCallouts(),dml=Limits.getDmlStatements();
                try { P05TarifasServicio.consultarYGuardar(id,3);System.assert(false); }
                catch(P05ConsultaTarifa.ConsultaException ex) {
                    System.assert(ex.getMessage().startsWith(category+' (requestId='));
                }
                System.assertEquals(before,countAll());System.assertEquals(calls+1,Limits.getCallouts());
                System.assertEquals(dml,Limits.getDmlStatements());
            }
        }
    }
    @IsTest static void rejectsExpiryAtSaveEvenIfValidAtReceipt() {
        Datetime received = Datetime.newInstanceGmt(2026,11,19,12,0,0);
        Datetime expiry = received.addSeconds(1);
        P05ConsultaTarifa.validateTimes(expiry.addHours(-24), expiry, received);
        String requestId = UUID.randomUUID().toString();
        Integer before = countAll();
        P05TarifasServicio.validateAtSave(expiry, Datetime.newInstance(expiry.getTime()-1), requestId);
        for (Integer elapsed : new List<Integer>{0,1,1000}) {
            try {
                P05TarifasServicio.validateAtSave(expiry, Datetime.newInstance(expiry.getTime()+elapsed), requestId);
                System.assert(false, 'No existe tolerancia de caducidad al guardar.');
            } catch (P05TarifasServicio.ServicioException ex) {
                System.assertEquals('INVALID_RESPONSE (requestId='+requestId+')', ex.getMessage());
            }
        }
        System.assertEquals(before,countAll());
    }
    @IsTest static void insertionFailureHasNoFalseSuccessOrLeakedPermit() {
        Id id=product('PROD-005').Id;
        System.runAs(actor('p05a')) {
            ProviderMock mock=new ProviderMock();mock.deleteProduct=true;
            Test.setMock(HttpCalloutMock.class,mock);Integer before=countAll();
            try { P05TarifasServicio.consultarYGuardar(id,1);System.assert(false); }
            catch(P05TarifasServicio.ServicioException ex) {
                System.assert(ex.getMessage().startsWith('SAVE_FAILED (requestId='));
                System.assert(!ex.getMessage().contains('FIELD_INTEGRITY_EXCEPTION'));
            }
            System.assertEquals(before,countAll());
            Database.SaveResult direct=Database.insert(new ConsultaTarifa__c(),false,AccessLevel.USER_MODE);
            System.assert(!direct.isSuccess());System.assertEquals(before,countAll());
        }
    }
    @IsTest static void newPriceCreatesNewSnapshotAndKeepsOriginal() {
        Id id=product('PROD-001').Id;
        System.runAs(actor('p05a')) {
            ConsultaTarifa__c original=P05TarifasServicio.listarPropias(1)[0].registro;
            ProviderMock mock=new ProviderMock();mock.unitPrice='20.00';Test.setMock(HttpCalloutMock.class,mock);
            ConsultaTarifa__c current=P05TarifasServicio.consultarYGuardar(id,3).registro;
            System.assertNotEquals(original.Id,current.Id);System.assertEquals(60.00,current.Total__c);
            System.assertEquals(59.70,P05TarifasServicio.obtener(original.Id).registro.Total__c);
            Datetime tied=Datetime.now().addDays(-1);
            Test.setCreatedDate(original.Id,tied);Test.setCreatedDate(current.Id,tied);
            List<Id> sorted=new List<Id>{original.Id,current.Id};sorted.sort();
            List<P05TarifasServicio.Detalle> history=P05TarifasServicio.listarPropias(100);
            System.assertEquals(2,history.size());
            System.assertEquals(sorted[1],history[0].registro.Id);
            System.assertEquals(sorted[1],P05TarifasServicio.listarPropias(1)[0].registro.Id);
        }
    }
    @IsTest static void productChangeDoesNotChangeHistoricalCopies() {
        Product2 p=product('PROD-001');
        User u=actor('p05a');ConsultaTarifa__c original;
        System.runAs(u){original=P05TarifasServicio.listarPropias(1)[0].registro;}
        p.Name='Nombre cambiado después';p.CodigoProveedor__c='PROD-777';update as system p;
        System.runAs(u){
            ConsultaTarifa__c stored=P05TarifasServicio.obtener(original.Id).registro;
            System.assertEquals('Producto ficticio uno',stored.NombreProducto__c);
            System.assertEquals('PROD-001',stored.CodigoProveedor__c);System.assertEquals(0,Limits.getCallouts());
        }
    }
    @IsTest static void historyEnforcesOwnerAndStableOrderWithoutCallouts() {
        User a=actor('p05a'),b=actor('p05b');Id own,foreignId;
        System.runAs(a){own=P05TarifasServicio.listarPropias(100)[0].registro.Id;}
        System.runAs(b){foreignId=P05TarifasServicio.listarPropias(100)[0].registro.Id;}
        System.runAs(a){
            System.assertEquals(1,[SELECT COUNT() FROM ConsultaTarifa__c WITH USER_MODE]);
            System.assertEquals(own,P05TarifasServicio.obtener(own).registro.Id);
            try{P05TarifasServicio.obtener(foreignId);System.assert(false);}
            catch(P05TarifasServicio.ServicioException ex){System.assertEquals('NOT_FOUND',ex.getMessage());}
            for(Integer maxResults:new List<Integer>{null,0,101}){
                try{P05TarifasServicio.listarPropias(maxResults);System.assert(false);}
                catch(P05TarifasServicio.ServicioException ex){System.assertEquals('INVALID_REQUEST',ex.getMessage());}
            }
            System.assertEquals(0,Limits.getCallouts());
        }
    }
    @IsTest static void expiredHistoryRemainsReadableWithoutCallout() {
        Id id=product('PROD-002').Id;
        System.runAs(actor('p05a')){
            ProviderMock mock=new ProviderMock();mock.expiresSoon=true;Test.setMock(HttpCalloutMock.class,mock);
            P05TarifasServicio.Detalle saved=P05TarifasServicio.consultarYGuardar(id,1);
            // Espera acotada a la caducidad real (~1 s), sin alterar reloj, datos o guardián.
            Datetime deadline=Datetime.now().addSeconds(3);
            while(Datetime.now()<saved.registro.CaducaEn__c && Datetime.now()<deadline){}
            Integer calls=Limits.getCallouts();
            P05TarifasServicio.Detalle historical=P05TarifasServicio.obtener(saved.registro.Id);
            System.assert(!historical.vigente);
            System.assertEquals(saved.registro.Total__c,historical.registro.Total__c);
            System.assertEquals(calls,Limits.getCallouts());
        }
    }
    @IsTest static void rejectsDirectInsertAndUserUpdatesDeletes() {
        System.runAs(actor('p05a')){
            ConsultaTarifa__c own=P05TarifasServicio.listarPropias(1)[0].registro;
            Database.SaveResult insertResult=Database.insert(own.clone(false,false,false,false),false,AccessLevel.USER_MODE);
            System.assert(!insertResult.isSuccess());
            System.assert(insertResult.getErrors()[0].getMessage().contains('P05_INTEGRITY'));
            Database.SaveResult updated=Database.update(new ConsultaTarifa__c(Id=own.Id,Total__c=1),false,AccessLevel.USER_MODE);
            System.assert(!updated.isSuccess());
            Database.DeleteResult deleted=Database.delete(new ConsultaTarifa__c(Id=own.Id),false,AccessLevel.USER_MODE);
            System.assert(!deleted.isSuccess());
            System.assertEquals(59.70,P05TarifasServicio.obtener(own.Id).registro.Total__c);
        }
    }
    @IsTest static void integrityRejectsSystemWritesAndSurvivesProductDeletion() {
        ConsultaTarifa__c own=[SELECT Id,Producto__c FROM ConsultaTarifa__c WITH SYSTEM_MODE LIMIT 1];
        Database.SaveResult updated=Database.update(new ConsultaTarifa__c(Id=own.Id,Total__c=1),false,AccessLevel.SYSTEM_MODE);
        System.assert(!updated.isSuccess());System.assert(updated.getErrors()[0].getMessage().contains('P05_INTEGRITY'));
        Database.DeleteResult deleted=Database.delete(own,false,AccessLevel.SYSTEM_MODE);
        System.assert(!deleted.isSuccess());System.assert(deleted.getErrors()[0].getMessage().contains('P05_INTEGRITY'));
        Database.DeleteResult productDeleted=Database.delete(new Product2(Id=own.Producto__c),false,AccessLevel.SYSTEM_MODE);
        System.assert(productDeleted.isSuccess());
        ConsultaTarifa__c preserved=[SELECT Id,Producto__c,NombreProducto__c,CodigoProveedor__c,Total__c FROM ConsultaTarifa__c WHERE Id=:own.Id WITH SYSTEM_MODE];
        System.assertEquals(null,preserved.Producto__c);
        System.assertEquals('Producto ficticio uno',preserved.NombreProducto__c);
        System.assertEquals('PROD-001',preserved.CodigoProveedor__c);
        System.assertEquals(59.70,preserved.Total__c);
        try{P05TarifasServicio.validarIntegridad();System.assert(false);}
        catch(P05TarifasServicio.ServicioException ex){System.assertEquals('INTEGRITY_CONTEXT_REQUIRED',ex.getMessage());}
    }
}
