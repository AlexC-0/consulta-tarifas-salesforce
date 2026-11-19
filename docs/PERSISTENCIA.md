# Carga, despliegue y demostración de persistencia

## Despliegue incremental de fase 3

Requiere la organización P05 y la conexión ya configuradas en fases anteriores.
El manifiesto de esta fase no recrea credenciales ni incluye secretos.
Desde salesforce/:

```powershell
sf.cmd project deploy start --manifest manifest/fase-3.xml --target-org p05-tarifas-dev --test-level RunSpecifiedTests --tests P05ConsultaTarifaTest --tests P05TarifasServicioTest --wait 10
```

Comprobar el resultado final. Una ejecución enviada o un estado parcial no acredita éxito.
Si sigue en curso, consultar project deploy report con el identificador devuelto
y el mismo destino explícito.

Asignar a cada usuario autorizado P05_Datos_Tarifas y P05_Consultar_Tarifas,
además de P05_Conexion_Proveedor ya existente. En esta demostración se añadieron
solo los dos conjuntos nuevos al administrador P05. No se crearon usuarios persistentes.

```powershell
sf.cmd org assign permset --name P05_Datos_Tarifas --target-org p05-tarifas-dev
sf.cmd org assign permset --name P05_Consultar_Tarifas --target-org p05-tarifas-dev
```

Estos comandos asignan al usuario autenticado, no prueban el recorrido de un comercial.
Los usuarios de permisos mínimos se ejercitan en la suite automatizada.
Una instalación desde cero debe preparar primero conexión y secreto según
[CONEXION](CONEXION.md); esta fase verifica la instalación incremental.

## Carga administrativa

En transacciones independientes y antes de cualquier callout:

```powershell
sf.cmd apex run --file scripts/cargar-productos.apex --target-org p05-tarifas-dev
sf.cmd apex run --file scripts/cargar-producto-negativo.apex --target-org p05-tarifas-dev
```

La primera carga prepara los tres productos normales. La segunda añade únicamente
el dato ficticio PROD-999 para el caso negativo. No sobrescriben incompatibilidades.
Volver a ejecutar la primera carga debe reutilizar los tres productos sin duplicados.
El comercial no recibe permiso de crear/editar productos para ejecutar estas cargas.

## Llamada y guardado

Arrancar el proveedor con su .env existente, autorizar el túnel temporal aplicable
y actualizar únicamente la URL de P05_Proveedor según [CONEXION](CONEXION.md).
No regenerar claves ni recrear la conexión.

```powershell
sf.cmd apex run --file scripts/consulta-guardar.apex --target-org p05-tarifas-dev
```

El script usa un Id de Product2 leído en Salesforce, cantidad 3 y el servicio
P05TarifasServicio. Comprueba 59.70 EUR y propiedad del usuario ejecutor.
Emite referencia autonumérica, importes, fechas e identificadores de correlación,
sin Id de Salesforce, usuario, organización, secreto o endpoint.

**Cada ejecución satisfactoria crea otra instantánea.** No repetirla para leer
la ya creada y no borrar automáticamente los resultados válidos.

## Caso negativo en otra transacción

```powershell
sf.cmd apex run --file scripts/consulta-negativa.apex --target-org p05-tarifas-dev
```

El producto específico PROD-999 está activo en Salesforce, pero no existe en el
proveedor. Se exige PRODUCT_NOT_FOUND, mismo número de consultas propias antes
y después y una llamada. Correlacionar requestId con HTTP 404 del proveedor.

## Lectura posterior sin proveedor

En otra transacción:

```powershell
sf.cmd apex run --file scripts/lectura-historico.apex --target-org p05-tarifas-dev
```

La lista acotada y el detalle usan exclusivamente Salesforce. El script toma la
consulta propia más reciente y emite su referencia y requestId; contrastarlos con
el resultado guardado para evitar confundir registros. Exige cero callouts.

Cerrar los procesos propios de proveedor y túnel y comprobar puerto 3055 libre.
Ejecutar otra vez solo lectura-historico.apex: debe devolver el mismo registro sin
necesitar la red del proveedor. No combinar varias consultas con insert dentro
de una única transacción.

## Evidencias y precauciones operativas

Conservar solo los campos saneados emitidos por los scripts y el log mínimo
requestId/estado/duración del proveedor. No guardar debug logs completos ni
salidas de autenticación. Los JSON de evidencia no deben incluir Ids privados.
El estado del túnel y la ausencia de listener se verifican fuera de Salesforce.

La fase 5 admite únicamente el margen fijo de emisión de 1000 ms definido en
[CLIENTE_APEX](CLIENTE_APEX.md). Si lo supera, se rechaza sin corregir fechas,
cambiar relojes ni reintentar. La recepción se conserva desde Http.send y la
caducidad se comprueba de nuevo antes del DML y en el trigger. Si vence en ese
intervalo no se guarda; un rechazo del trigger se traduce a SAVE_FAILED con rollback.

Conservar el registro válido y los cuatro productos ficticios de demostración.
Los históricos no se actualizan automáticamente, incluso cuando caducan.

## Continuidad de fase 4

Cliente HTTP, servicio e integridad conservados sin cambios. La interfaz añade
controlador/DTO/LWC y reutiliza sus operaciones. Los ejemplos administrativos anteriores
siguen siendo diagnósticos; el recorrido comercial de fase 4 consta en [FASE-4](FASE-4.md).
Acceso y despliegue incremental de la interfaz en [USO](USO.md).
Se conservan P05-000000 y P05-000001.
