# Modelo de datos — fase 3

## Product2

Se reutilizan Name (255 caracteres) e IsActive. CodigoProveedor__c es Text(8),
único, sensible a mayúsculas y marcado como External ID. Una regla rechaza
códigos no vacíos que no cumplan ^PROD-[0-9]{3}$. Se permiten otros productos
sin código en la organización; el servicio P05 los rechaza.

La carga administrativa prepara tres productos ficticios, sin precios locales:
PROD-001, Kit de conexión de demostración; PROD-002, Módulo de control de
demostración; PROD-003, Conector auxiliar de demostración.
La carga negativa independiente añade PROD-999, Producto de demostración sin tarifa.
No hay Price Books ni sincronización de catálogo.

Los scripts comparan nombre, código y actividad antes de insertar. Una coincidencia
incompatible detiene toda la carga; no se corrige ni sobrescribe automáticamente.
La carga es repetible por código único; no se promete resolver toda carrera concurrente.

## ConsultaTarifa__c

Objeto privado, Name autonumérico P05-{000000}. Sin compartición adicional.
OwnerId se fija al usuario ejecutor en servidor; CreatedById y CreatedDate
aportan la autoría estándar.

| Campo | Tipo / capacidad |
| --- | --- |
| Producto__c | Lookup Product2, SetNull, sin cascada |
| NombreProducto__c | Text(255), copia histórica |
| CodigoProveedor__c | Text(8), copia histórica |
| Cantidad__c | Number(5,0); servicio exige entero 1–10000 |
| PrecioUnitario__c | Number(8,2), máximo 999999.99 |
| Total__c | Number(12,2), máximo 9999999900.00 |
| Moneda__c | Text(3), servicio admite EUR |
| EmitidaEn__c | DateTime del proveedor validado |
| RecibidaEn__c | DateTime generado por el servicio en Salesforce |
| CaducaEn__c | DateTime de caducidad validado |
| RequestId__c / QuoteId__c | Text(36), UUID validados |
| TariffVersion__c | Text(64), no vacío ni solo espacios |
| SchemaVersion__c | Text(8), contrato admitido "1" |

Los nombres/códigos son valores almacenados, no fórmulas. La prueba de nombre
de 255 caracteres y total máximo comprueba que no se recortan esos valores.
Los DateTime persistidos tienen resolución de segundos: la validación HTTP
conserva la precisión de milisegundos del contrato antes de insertar, mientras
la lectura devuelve la precisión realmente almacenada por Salesforce.
No se habilita multimoneda.

Salesforce rechazó Restrict para un lookup hijo de Product2. Se usa SetNull:
borrar el producto no borra la consulta ni sus copias históricas; solo elimina
el enlace. El comercial P05 no tiene permiso de borrado de productos.
La prueba automatizada verifica esa conservación tras un borrado administrativo.
Esta limitación de Product2 motivó la alternativa; no se cambió el modelo de negocio.

Los campos personalizados no son obligatorios globalmente para permitir aplicar
FLS explícita. La obligatoriedad y coherencia se garantizan en el servicio y el
trigger: ninguna inserción directa es válida, incluso con campos incompletos.
No existen rutas públicas para aportar una instantánea ya construida.

## Transacciones

1. Cargar productos y asignar permisos en transacciones independientes.
2. Consultar un producto: validar autorización, acceso y cantidad antes del HTTP.
3. Validar la respuesta con P05ConsultaTarifa, construir la instantánea en servidor.
4. Crear un savepoint después del callout; insertar en USER_MODE y releer datos
   persistidos. Ante fallo, rollback y SAVE_FAILED con requestId.
5. Leer el histórico en otra transacción, sin callout.

Cada éxito crea un registro nuevo. No se actualizan instantáneas ni se promete
ejecución exactamente una vez. No ejecutar dos operaciones callout+insert
consecutivas dentro de una transacción: el primer insert deja trabajo pendiente.

La caducidad se calcula al leer; una tarifa caducada permanece accesible.
El aviso del DTO es: "Información obtenida en esta consulta; no se actualiza automáticamente".
