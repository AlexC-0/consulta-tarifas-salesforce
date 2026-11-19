# Seguridad e integridad — fase 3

## Permisos

Perfil base usado en pruebas: Minimum Access - Salesforce, sin rol ni permisos amplios.
Tres conjuntos separan las responsabilidades:

| Permission Set | Concesiones |
| --- | --- |
| P05_Datos_Tarifas | Leer Product2/código; crear y leer ConsultaTarifa__c y sus campos; sin editar ni borrar objetos, View All o Modify All |
| P05_Consultar_Tarifas | Custom Permission P05_Consultar_Tarifas y acceso a P05TarifasServicio |
| P05_Conexion_Proveedor | Conjunto existente: cliente HTTP y principal externo P05_Compartido |

La creación exige FLS de escritura de campos, pero no permiso de edición del objeto.
Así se permite insert USER_MODE y se niega update/delete ordinario. El trigger
cierra la posibilidad de insertar valores arbitrarios con ese permiso de creación.

P05TarifasServicio es with sharing. Comprueba permiso funcional, CRUD y FLS antes
del callout. Consulta Product2 con WITH USER_MODE; escribe con insert as user
y usa queryWithBinds con AccessLevel.USER_MODE para el histórico.
No hay escrituras SYSTEM_MODE en el servicio.

El detalle y la lista filtran además OwnerId=usuario actual, incluso para el
administrador que use este servicio. La lista admite 1–100 registros y ordena
por CreatedDate DESC, Id DESC. No hay callouts en esas operaciones.
El acceso administrativo directo a los datos queda fuera de esa restricción de servicio.

Referencia: [operaciones de datos en modo usuario](https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-classes-enforce-usermode.html).
El modo se expresa explícitamente para no depender del comportamiento predeterminado
de una versión de API.

## Control de creación e inmutabilidad

P05ConsultaTarifaIntegridad se ejecuta before insert/update/delete y after undelete.
La clase de servicio conserva un candidato privado, sin setter ni TestVisible,
creado exclusivamente a partir del producto leído y la respuesta HTTP validada.

Justo antes del insert, el servicio copia ese candidato al contexto privado.
El trigger consume el contexto una sola vez y exige una sola fila, el propietario
actual y coincidencia de todos los campos de instantánea. El servicio limpia
siempre el contexto en finally. No hay interruptor público, token aceptado del
consumidor ni excepción Test.isRunningTest.

Una inserción directa, edición, borrado o recuperación no dispone de ese contexto
y recibe P05_INTEGRITY. La entrada pública del trigger únicamente comprueba y
rechaza; llamarla fuera del trigger también falla. No concede autorización.

La autorización funcional y el control de integridad son distintos.
Un usuario con Create sigue sin poder insertar arbitrariamente por UI/API.
El trigger también rechaza update/delete en SYSTEM_MODE con la configuración
actual. La eliminación del producto puede limpiar el lookup por SetNull, pero
no altera los valores históricos copiados.

No es un archivo de auditoría inviolable: un administrador con capacidad para
cambiar código/configuración puede desactivar o sustituir estos controles.
Automatizaciones futuras sobre el objeto deben respetar el mecanismo; esta fase
no añade Flows ni triggers adicionales que modifiquen instantáneas.

## Fallos y datos externos

El consumidor solo proporciona Id de Product2 y cantidad Decimal.
Nombre y código salen de Salesforce, propietario del contexto ejecutor,
fecha de recepción del reloj de Salesforce e importes de la respuesta validada.
No se aceptan secretos, URL, precio, propietario o respuesta externa como argumentos.

El cliente conserva categorías y requestId para errores HTTP, timeout y respuesta
inválida. Ninguno crea instantáneas. Un fallo de inserción o relectura provoca
rollback y SAVE_FAILED, sin devolver ID ni detalles internos de DML.

## Pruebas y límites

Usuarios, Permission Sets parciales y datos de prueba se crean solo en tests y
se revierten al terminarlos. System.runAs se combina con USER_MODE y comprobaciones
explícitas de permisos; no se usa como sustituto de CRUD/FLS.

Los fixtures históricos se generan llamando al propio servicio en trabajos
Queueable exclusivos de test, en transacciones separadas. El servicio de producción
es síncrono. El mock verifica que el servicio no añade DML antes del callout;
el contador base puede incluir operaciones del fixture y System.runAs.

Se comprueban falta de permiso funcional, objeto Product2 inaccesible, ausencia
de permisos de datos y ausencia de FLS de creación de Total__c, antes del HTTP.
También propietario/autoría, acceso propio/ajeno, escritura directa,
update/delete, contexto privado tras un fallo, histórico caducado y orden estable.

Para provocar una FK inválida, un mock elimina un producto de prueba sin
instantáneas mediante el usuario que lo creó. No se añade ninguna puerta de
prueba al servicio ni se altera la integridad. Otra prueba espera brevemente
la caducidad real de una tarifa próxima a vencer; no cambia reloj o campos.

Las comprobaciones con usuarios mínimos son automatizadas. La demostración
HTTPS real se realiza como System Administrator; todavía no acredita el recorrido
interactivo comercial, reservado a la fase del LWC.
