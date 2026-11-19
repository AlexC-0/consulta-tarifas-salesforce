# Uso comercial y despliegue de fase 4

## Acceso y permisos

Desde el Iniciador de aplicaciones, abrir **P05 Tarifas** y su pestaña **Consulta de tarifas**.
La entrada está versionada como CustomApplication P05_Tarifas y CustomTab P05_Consulta.
El componente p05Tarifas está expuesto como lightning__Tab para escritorio.

Perfil de demostración: Minimum Access - Salesforce, sin rol. Asignar únicamente
P05_Datos_Tarifas, P05_Consultar_Tarifas y P05_Conexion_Proveedor al usuario autorizado.
P05_Consultar_Tarifas incluye acceso al controlador, aplicación/pestaña y el permiso
específico LightningExperienceUser, ausente del perfil mínimo en esta organización.
P05_Conexion_Proveedor añade lectura de UserExternalCredential para que Salesforce
use el principal protegido; no permite consultar su secreto por SOQL/Apex/API.
No se requieren privilegios administrativos ni View All/Modify All.

## Nueva consulta

1. Seleccionar producto por nombre y código. Se muestran productos activos con código
   válido, ordenados por nombre/Id y acotados a 200 candidatos. PROD-999 es un fixture
   negativo conservado en Salesforce y excluido de este selector comercial.
2. Introducir una cantidad entera entre 1 y 10.000.
3. Pulsar **Consultar y guardar tarifa** una vez. Los controles se bloquean mientras
   está pendiente. Solo se envían Id de Product2 y cantidad.
4. Comprobar la confirmación y referencia. El detalle muestra los valores persistidos,
   importes de dos decimales en EUR, fechas en la zona horaria del usuario y caducidad.

La consulta nueva necesita proveedor y túnel activos y autorizados. Cada éxito crea
otra instantánea: no usar este botón como lectura de una consulta anterior.
El navegador no calcula precios ni llama al proveedor; el controlador delega al servicio.
La vigencia visual se recalcula cada segundo a partir de la fecha de caducidad; no
actualiza importes ni contacta al proveedor. Depende del reloj del navegador.

## Histórico y fallos

**Mis consultas** lista las 50 más recientes del usuario, ordenadas por fecha/Id.
**Actualizar histórico** y el botón de referencia solo leen Salesforce. Funcionan con
proveedor y túnel detenidos. Las tarifas vencidas siguen disponibles, marcadas Caducada.
No hay acciones de editar, borrar o actualizar automáticamente una tarifa.

Un intento nuevo limpia el resultado anterior. Los errores se presentan en castellano,
con requestId cuando está disponible, sin respuestas externas ni detalles internos.
Si el guardado tuvo éxito pero falla el refresco, se conserva su confirmación y referencia.
Si se pierde la respuesta, revisar Mis consultas antes de repetir: no hay reintentos
automáticos ni garantía de idempotencia entre dos pulsaciones separadas.
Las respuestas tardías no sustituyen un detalle seleccionado después.

## Despliegue incremental comprobado

Requiere fases 1B–3 instaladas, conexión y clave existentes; no recrearlas.
Desde salesforce/:

```powershell
npm.cmd ci --ignore-scripts
npm.cmd run test:unit
sf.cmd project deploy start --manifest manifest/fase-4.xml --target-org p05-tarifas-dev --test-level RunSpecifiedTests --tests P05ConsultaTarifaTest --tests P05TarifasServicioTest --tests P05TarifasControladorTest --wait 10
```

Comprobar el resultado final de despliegue. El manifiesto contiene cuatro clases nuevas,
un LWC, los conjuntos de consulta y conexión, aplicación y pestaña. .forceignore excluye Jest y sus
archivos de prueba del despliegue. Dependencias locales con lockfile, sin herramientas
globales. Esta instalación incremental no acredita una instalación desde cero.

## Demostración reproducible

Preparar el usuario comercial únicamente con autorización de Alex. Para Login As,
registrar el estado inicial de la política y restaurarlo después. Usar el cambio oficial
a Lightning dentro de esa sesión; comprobar identidad antes de guardar, pues una
pestaña administrativa previa no demuestra los permisos del comercial.

Autorizar un túnel temporal hacia 127.0.0.1:3055, reutilizar la clave existente y actualizar
solo la URL de Named Credential. Hacer la consulta desde el LWC. Contrastar propietario,
autoría y requestId con lecturas administrativas y el log mínimo del proveedor; estas
lecturas son evidencia complementaria y no se presentan como API ordinaria del comercial.

Comprobar cantidad inválida, aislamiento del histórico/detalle y un fallo sin insert ni
éxito anterior. Cerrar los procesos propios, verificar puerto libre y repetir únicamente
lectura del histórico/detalle. Conservar las instantáneas válidas y evidencia saneada.
No alterar el reloj ni relajar validaciones para forzar el resultado. Robustez temporal
y matriz final de fallos reales pertenecen a fase 5; la V1 no se declara cerrada.

Resultados y límites de la ejecución: [STATUS](STATUS.md).
