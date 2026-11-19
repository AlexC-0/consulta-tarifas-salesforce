# Estado — fase 4 completada, 19/11/2026

Interfaz comercial desplegada y recorrido real comprobado: LWC → controlador →
servicio existente → HTTPS autenticado → instantánea privada → resultado/histórico.
**V1 no terminada**: robustez temporal y matriz final de fallos reales pertenecen a fase 5.

## Base, alcance y acceso

Ruta: C:\Users\kaosk\source\repos\consulta-tarifas-salesforce.
Rama main; origin https://github.com/AlexC-0/consulta-tarifas-salesforce.git.
Inicio limpio, HEAD/origin main en 148d0e0b8654efcb1d57ba3af5b211f98083f9a6.
Alex publicó fase 3. Cambios sin staging, sin commits ni push de Codex.
No se inspeccionaron ni modificaron P01–P04; sin Gmail ni herramientas globales nuevas.

Organización P05 e identidad comprobadas, destino explícito p05-tarifas-dev, API 68.0.
Conexión, principal y clave reutilizados; solo se actualizó el endpoint temporal.
El estado publicado de fase 3 se conserva íntegro en [FASE-3](FASE-3.md), junto con
sus evidencias y los históricos anteriores.

Acceso: Iniciador de aplicaciones → **P05 Tarifas** → **Consulta de tarifas**.
[Guía de uso y despliegue](USO.md), [seguridad](SEGURIDAD.md).

## Implementación

- Controlador with sharing con cuatro operaciones Aura imperativas, no cacheables.
  Delega guardado/histórico/detalle al servicio; guardado acepta únicamente Id y cantidad.
- DTO de nivel superior P05ProductoOpcion y P05TarifaVista, propiedades AuraEnabled.
  No se expone la clase interna Detalle ni SObject/propietario/datos innecesarios.
- Productos con autorización funcional, CRUD/FLS y USER_MODE; activos con código válido,
  orden nombre/Id y límite 200 candidatos. PROD-999 excluido solo del selector normal;
  fixture y tres productos normales intactos.
- LWC p05Tarifas con componentes base y SLDS: enteros 1–10000, carga y doble envío
  bloqueado; confirmación con referencia y valores persistidos; EUR con dos decimales,
  fechas en zona del usuario y vigencia recalculada cada segundo desde caducidad.
- Mis consultas: 50 propias; detalle y actualización explícita solo de Salesforce.
  Errores seguros en castellano con requestId cuando existe y canales independientes.
  Refresco fallido conserva confirmación; nueva petición limpia el detalle anterior;
  respuestas tardías no pisan selección posterior. Sin reintentos ni precios calculados en JS.
- Aplicación P05_Tarifas y pestaña P05_Consulta; dos conjuntos existentes actualizados.
  Cliente HTTP, servicio e integridad permanecen sin cambios.

## Perfil y permisos reales

Se comprobó una licencia Salesforce libre. Alex autorizó crear Comercial Demo P05,
perfil **Minimum Access - Salesforce**, sin rol, sin enviar correos ni cambiar
credenciales existentes. Cuenta conservada, con exactamente tres conjuntos:
P05_Datos_Tarifas, P05_Consultar_Tarifas y P05_Conexion_Proveedor.

El perfil carecía de LightningExperienceUser y lectura UserExternalCredential.
Se añadieron esos permisos específicos a consulta y conexión respectivamente.
Comprobación final: cero concesiones de ViewAllData, ModifyAllData,
CustomizeApplication o ManageUsers; sin View All/Modify All de objetos P05.

La navegación inicial recuperaba una pestaña administrativa, descartada como evidencia
comercial. Se siguió el enlace oficial Login As a nivel de pestaña y se verificó
la identidad efectiva antes de guardar. No se convirtió al administrador ni se usó
Apex anónimo como sustituto del recorrido interactivo.

## Pruebas y despliegue final

| Comprobación | Resultado |
| --- | --- |
| manifest/fase-4.xml | Succeeded, **9 componentes**, 0 errores |
| P05ConsultaTarifaTest | **16/16** |
| P05TarifasServicioTest | **13/13** |
| P05TarifasControladorTest | **7/7** |
| Total Apex | **36/36**, 0 fallos |
| Jest local | **21/21**, 0 fallos |
| Endpoint temporal | Succeeded, 1 Named Credential |
| Conversión DX local | Estado 0 |
| Proveedor/OpenAPI | Sin cambios; 42/42 fase 2 reutilizadas, no repetidas |

Comandos reproducibles en [USO](USO.md). Jest cubre carga/vacío, entradas inválidas,
argumentos, doble clic, confirmación/formato, errores seguros, recuperación, éxito
antiguo, fallo de refresco, carreras, deduplicación, caducidad y desconexión.
Apex cubre filtros/permisos, DTO, delegación, 404 sin insert, aislamiento/histórico
sin callouts y traducción segura, además de cliente/servicio/integridad anteriores.
Jest no acredita integración ni permisos reales de Salesforce.

Se corrigieron el form factor Large de la aplicación y exclusiones Jest en .forceignore
tras el primer despliegue fallido. Se ajustó una expectativa de atributos numéricos
en los stubs de Jest. Los intentos fallidos no se contabilizan como éxitos.
Apex se repitió tras cambios de permisos; Jest no se repitió por rutina tras pasar.

## Demostración comercial

| Caso | Evidencia |
| --- | --- |
| Selector | Tres productos normales; PROD-999 ausente |
| Cantidad 0 | Rechazo visible antes del envío |
| Histórico inicial | Vacío; P05-000000 administrativa ausente |
| PROD-001 × 3 | **P05-000001**, 19.90 × 3 = **59.70 EUR**, confirmación y detalle |
| Correlación | **680c6dff-0916-4b82-a0cc-7a06bdfb783f**, exactamente un HTTP 200 proveedor |
| Propietario y autoría | Ambos del comercial; lectura administrativa de contraste |
| Abrir histórico propio | P05-000001 abierta desde su botón de referencia |
| Detalle ajeno | «La consulta histórica no está disponible para tu usuario» |
| Proveedor/túnel apagados | Recarga, Actualizar histórico y detalle propio correctos |
| Nueva consulta tras apagado | HTTP_ERROR seguro, 0 nuevos registros, sin detalle/éxito anterior |
| Lectura tras ese error | Histórico y detalle P05-000001 disponibles de nuevo |

El sondeo de detalle ajeno usó un evento rowaction del LWC con el Id administrativo,
bajo la sesión comercial verificada; invocó el controlador real.
Propiedad y recuentos se contrastaron mediante lecturas administrativas complementarias,
no presentadas como API ordinaria. Recuento final: **2 registros**, uno de cada usuario.
P05-000000 y su requestId de fase 3 se conservan intactos.

[Evidencia saneada](evidencias-fase-4.json), [detalle sin proveedor](evidencias/fase-4/detalle-sin-proveedor.png)
y [error sin proveedor](evidencias/fase-4/error-sin-proveedor.png). Capturas limitadas
al componente y revisadas visualmente, sin usuario, dominio, IDs privados ni secretos.

## Reloj y restauración

Una llamada inicial falló por permisos de credencial, sin llegar al proveedor ni guardar.
Tras corregirlos, otra obtuvo HTTP 200 pero fue rechazada por INVALID_RESPONSE sin insert.
Sonda administrativa de diagnóstico sin DML: emisión **13 ms futura** respecto a recepción;
correlación, producto, cantidad, importes y duración exacta de 24 horas correctos.

Alex autorizó expresamente la sincronización de fase 4. w32tm /resync /rediscover
terminó con código 0; la medición posterior aún mostraba adelanto local de 49.9497 ms.
Se completó corrección puntual con tres muestras NTP correlacionadas de la misma
fuente time.windows.com. Medición posterior: offset +6.01825 ms (local ligeramente
por detrás). Sin configuración persistente, offsets del proveedor o validaciones
relajadas. La siguiente consulta del LWC comercial guardó P05-000001.

Proveedor/túnel propios detenidos y puerto 3055 sin listener antes de la prueba offline.
Endpoint temporal inactivo; clave y principal conservados.
Login As comenzó en false, se habilitó con autorización, se cerró la sesión comercial
y se restauró **false**, comprobado tras recarga. Cuenta y registros válidos conservados.

## Límites y siguiente paso

Instalación incremental verificada; instalación limpia desde cero no ejecutada.
La caducidad visual depende del reloj del navegador. La validación Apex sigue
siendo estricta y sensible a desfases pequeños. Sin idempotencia entre pulsaciones
separadas: si falta confirmación, revisar el histórico antes de repetir.
No hay bloqueos pendientes de fase 4. Robustez temporal y matriz final de fallos
reales quedan para fase 5, con nuevo encargo. **No declarar V1 cerrada.**

Revisión y publicación manual de Alex. Codex no realiza staging, commit ni push.

## Revisión local final

99 archivos versionables revisados: 11 JSON, 36 XML y 57 enlaces relativos correctos.
Escaneo en memoria sin clave, endpoint temporal, dominio/usuario ni IDs privados.
.env, .local, .sf y node_modules excluidos. Histórico fase 3 idéntico al STATUS
del commit base. Cliente, servicio, proveedor y OpenAPI sin cambios.
Git sin staging; HEAD y origin/main siguen en 148d0e0. Sin commits ni push.
