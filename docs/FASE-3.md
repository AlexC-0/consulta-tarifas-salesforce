# Estado — fase 3 completada, 19/11/2026

Servidor completo: Product2 + cantidad → autorización/validación → HTTPS →
respuesta validada → ConsultaTarifa__c persistida. Histórico propio sin callouts.
V1 no terminada: quedan LWC, demostración comercial y matriz final de fallos reales.

## Base y alcance

Base de fase 2: `ae25cecd4ae10b9a7ecf9f03552074937f0e6982`.

Organización P05 reutilizada e identidad contrastada antes de desplegar.
Destino explícito p05-tarifas-dev, API 68.0, Developer Edition.
Se mantienen cliente, contrato, secreto y conexión anteriores.
[Histórico fase 2](FASE-2.md), [fase 1B](FASE-1B.md) y sus JSON se conservan.

## Implementación

- Product2.CodigoProveedor__c único y con formato, sin precios locales.
- ConsultaTarifa__c privada: 14 campos personalizados, autonumérico, propietario
  y autoría estándar. Nombres históricos de 255 caracteres; total Number(12,2).
- Servicio separado del cliente HTTP. Permiso funcional y CRUD/FLS antes del
  callout; consultas y escritura USER_MODE, sin DML previo a la llamada.
- Un contexto privado, de un solo uso y sin setter/TestVisible, permite solo
  el insert construido por el servicio. Trigger contra altas directas,
  update, delete y undelete; sin Test.isRunningTest ni interruptores públicos.
- Savepoint después del callout; rollback y SAVE_FAILED si falla persistencia
  o relectura. Errores del proveedor conservan categoría y requestId.
- Lista propia de 1–100 filas, CreatedDate DESC e Id DESC; detalle propio,
  vigencia calculada al leer y aviso de que no se actualiza automáticamente.
- Sin LWC, @AuraEnabled, asincronía de producción, reintentos ni Price Books.

Detalles: [MODELO](MODELO.md), [SEGURIDAD](SEGURIDAD.md), [PERSISTENCIA](PERSISTENCIA.md).

## Decisiones y ajustes verificados

Salesforce rechazó Restrict en el lookup hacia Product2. La alternativa SetNull
no borra consultas en cascada: conserva copias históricas y elimina solo el enlace
si un administrador borra el producto. Prueba automatizada aprobada.

Los DateTime persistidos se leen con resolución de segundos. La validación del
cliente conserva milisegundos y duración exacta de 24 horas antes de insertar.
Se documenta la precisión real del almacenamiento, sin añadir tolerancias al reloj.

Los primeros tests detectaron que el contador DML incluía trabajo del fixture y
System.runAs. El mock compara contra el contador previo y exige cero DML añadido
por el servicio antes del HTTP. Los históricos de test se crean por el propio
servicio en transacciones Queueable exclusivamente de test; sin bypass del guardián.

## Despliegue y pruebas

| Comprobación | Resultado |
| --- | --- |
| Despliegue incremental final con manifest/fase-3.xml | Succeeded, **25 componentes**, 0 errores |
| P05ConsultaTarifaTest | **16/16** aprobadas |
| P05TarifasServicioTest | **13/13** aprobadas |
| Total Apex | **29 ejecutadas, 29 aprobadas, 0 fallidas**, sin advertencias de cobertura |
| Named Credential para demostración | Succeeded, **1 componente**; únicamente nueva URL temporal |
| Conversión DX local | Correcta, estado 0 |
| Proveedor/OpenAPI | Sin cambios; 42/42 de fase 2 reutilizadas, no repetidas |

Pruebas: todos los campos guardados, cantidades 1/10000, total máximo
9999999900.00, nombre 255 caracteres, validación previa, producto inactivo/sin
código/inaccesible, permiso funcional/objeto/FLS, 404/timeout/respuesta inválida,
fallo real de FK con cero instantáneas nuevas, nuevo precio sin alterar anterior,
cambios/borrado de producto, histórico caducado, orden estable, usuarios propios/
ajenos e intentos de escritura directa. Usuarios y permisos parciales solo de test,
sin nuevas cuentas persistentes.

## Carga real

Se asignaron al administrador P05 los conjuntos nuevos P05_Datos_Tarifas y
P05_Consultar_Tarifas. P05_Conexion_Proveedor ya estaba asignado.
No se ampliaron privilegios generales.

Carga normal: **3 creados**. Repetición: **0 creados y 3 reutilizados**.
Carga negativa independiente: **1 creado**, PROD-999.
No se modificaron productos incompatibles ni datos anteriores.
Cada carga se ejecutó en transacción separada.

## Evidencia real y persistencia

| Caso | Resultado | Referencia / requestId |
| --- | --- | --- |
| PROD-001 × 3 | 200 proveedor; **59.70 EUR guardados** | **P05-000000** / ae786682-b496-42e6-87c2-5bffc4e2592e |
| PROD-999 × 1 | PRODUCT_NOT_FOUND / 404; **0 registros nuevos** | 2f02248d-226c-47c0-844d-6b3190bb6271 |
| Lectura en otra transacción | Misma referencia, total y requestId; 0 callouts | P05-000000 |
| Lectura con proveedor/túnel detenidos | Misma referencia, total y requestId; **0 callouts** | P05-000000 |

El caso negativo se ejecutó antes del guardado satisfactorio: recuentos 0 → 0.
La consulta válida posterior dejó una instantánea, conservada como evidencia.
Se contrastaron los requestId del registro y del 404 con los logs mínimos del
proveedor, exactamente una coincidencia por llamada.
[Evidencia saneada completa](evidencias-fase-3.json), sin IDs de Salesforce.

Perfil real confirmado: **System Administrator**, UserType Standard.
Esto se distingue de los tests con usuarios mínimos y no acredita todavía una
demostración interactiva comercial.

## Reloj, restauración y cierre

Dos intentos de guardado fueron rechazados por INVALID_RESPONSE antes de insertar.
El diagnóstico observó emisión 42 ms futura respecto a Salesforce, con importes,
correlación y duración correctos. Recuento posterior: cero instantáneas.

La sincronización puntual de Windows mediante w32tm /resync /rediscover,
con elevación, terminó con código 0, pero mantenía unos
91 ms de adelanto. Se completó el ajuste puntual con tres muestras NTP correlacionadas
de la misma fuente time.windows.com y Set-Date, sin cambios de configuración
persistente. Medición seleccionada previa: -93.1574 ms; posterior: +13.05225 ms
(reloj local ligeramente por detrás). La llamada siguiente fue válida.
No se alteraron fechas del proveedor ni validaciones del cliente.

El Quick Tunnel de fase 3 se limitó a 127.0.0.1:3055 durante la
demostración. Binding verificado. Túnel y proveedor propios detenidos; puerto
3055 sin listeners. La lectura posterior se ejecutó después de ese cierre.

La clave y el principal se conservan. Se conservan los cuatro productos ficticios
y la instantánea válida; no se borra automáticamente evidencia de negocio.
El endpoint temporal queda inactivo hasta una nueva ejecución autorizada.
No hay bloqueos pendientes para cerrar fase 3.

## Límites de la fase

La interfaz LWC, el recorrido comercial y la matriz final de fallos reales quedaron
fuera de esta fase. Su evolución se documenta en [STATUS](STATUS.md).
La instalación probada es incremental sobre P05; no se ha ejecutado una instalación
limpia desde cero.

## Revisión local final

Al finalizar la fase 3 se revisaron 74 archivos versionables: nueve JSON/plantillas, 30 XML/plantillas,
tres scripts PowerShell y 39 enlaces relativos correctos. Clave, ID/dominio/usuario
privado y URL temporal ausentes de los archivos versionables, comprobados en memoria
sin mostrar valores. .env, .local y .sf siguen excluidos de Git.
Resultados de fase 2 conservados.

Se conservan originales, herramientas, evidencia saneada y conversión local.
No se guardaron logs de depuración Apex completos. Puerto 3055 libre al cierre.
