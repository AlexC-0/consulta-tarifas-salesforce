# V1 — Matriz de aceptación definitiva

**V1 completada y aceptada dentro del alcance documentado, con limitaciones conocidas.**
Aceptación definitiva registrada el **19/11/2026**, sobre la revisión final publicada
en `061485df3455dab9296950a7bdf5df33630ab069`. La revisión de fase 6 se realizó
sobre el diagnóstico `756e931dbb2e78f4d3bdf64c762738f71344e976`; la implementación
funcional corresponde a `3f6a4dcd9aa08ce3884a78ef9dc252cf684ede16`.
La matriz funcional y sus limitaciones quedan aceptadas para V1. «Verificado»
identifica evidencia histórica; no representa una ejecución nueva por este cierre.
El registro documental local queda pendiente de publicación. No se ejecutan pruebas,
servicios ni despliegues ni se modifican retrospectivamente los JSON de evidencia.

## Fuentes y capas de evidencia

Las reglas proceden de [PROJECT_BRIEF](PROJECT_BRIEF.md), su versión inicial en
`603ebd1`, [OpenAPI](openapi.json) y las decisiones temporales de [fase 5](FASE-5.md).
No se añaden requisitos de negocio ni se convierten límites en defectos por defecto.

| Referencia | Evidencia concreta | Qué demuestra y qué no |
| --- | --- | --- |
| E1 | [Fase 1B](evidencias-fase-1b.json): `records`, `validKeyRestored` | Callout administrativo 200→401→200 con cambio real de clave; evidencia histórica, no nueva prueba comercial |
| E2 | [Fase 2](evidencias-fase-2.json): `records`, `providerTestsPassed`, `apexTestsPassed` | Tres productos y 404 por HTTPS; 42 proveedor y 16 Apex de aquella versión |
| E3 | [Fase 3](evidencias-fase-3.json): `productLoads`, `saved`, `negative`, `readProviderStopped` | Persistencia administrativa, carga repetible, conservación y lectura sin proveedor; 29 Apex históricos |
| E4 | [Fase 4](evidencias-fase-4.json): `commercial`, `ui`, `saved`, `offline`, `deployment`, `jest` | Sesión de demostración comercial con perfil mínimo, P05-000001, aislamiento y lectura offline; nueve componentes, 36 Apex y 21 Jest de esa fase |
| E5 | [Fase 5](evidencias-fase-5.json): `local`, `deployment`, `serviceReal`, `commercialFailures`, `commercialRecovery`, `resume` | 40 Apex con mocks, 30 Jest, 42 proveedor por inyección/contrato más una prueba HTTP real; ocho componentes incrementales y recorrido comercial del código funcional final |
| E5B | [Fase 5B](evidencias-fase-5b.json): `matrix`, `instrumentation`, `snapshots`, `tests`, `restoration` | 14 operaciones A/B/C, 18 entradas, seis callouts; tres pruebas locales afectadas; no es un nuevo recorrido comercial |

Las pruebas con HttpCalloutMock no prueban red; Jest no prueba permisos reales ni
sesión Salesforce. La inyección Fastify no equivale a HTTP loopback. Las sondas
administrativas complementan la evidencia comercial, no la sustituyen. Las cifras
entre fases no se suman como pruebas distintas ni como una suite final nueva.

## Matriz funcional

Los nombres de métodos de prueba permiten localizar la comprobación exacta en
[cliente Apex](../salesforce/force-app/main/default/classes/P05ConsultaTarifaTest.cls),
[servicio](../salesforce/force-app/main/default/classes/P05TarifasServicioTest.cls),
[controlador](../salesforce/force-app/main/default/classes/P05TarifasControladorTest.cls)
y [Jest](../salesforce/force-app/main/default/lwc/p05Tarifas/__tests__/p05Tarifas.test.js).

| Criterio y comportamiento requerido | Implementación | Evidencia concreta y fase | Resultado y límite aceptado |
| --- | --- | --- | --- |
| Catálogo: tres productos ficticios, selección por producto activo/código | [Proveedor](../proveedor/src/app.ts), `listarProductos`, [carga](../salesforce/scripts/cargar-productos.apex) | E2 `records`; E4 `ui.normalProducts`, `negativeFixtureExcluded`; `productsAreFilteredOrderedAndMinimal` en E5 | Verificado. El selector admite hasta 200 candidatos y excluye PROD-999; no es sincronización de catálogo |
| Cantidad: entero 1–10.000; rechazo antes del callout | Cliente/servicio/controlador y `handleSave` del LWC | `rejectsInvalidInputBeforeCallout`, `rejectsInputsAndUnavailableProducts`, `invalidInputAndUnauthorizedSaveNeverCallProvider` en E5; E4 `quantityZeroRejected` | Verificado. Fronteras automatizadas; no se atribuye cada valor a una prueba UI real |
| Importes: EUR, precio positivo ≤999999.99, dos decimales, total exacto | Céntimos enteros en proveedor; Decimal/regex en cliente; Number en metadata | `rejectsInvalidAmounts`, `rejectsTotalPrecisionTypeAndMismatch`, `savesMaximumAmountAndQuantity` en E5; E2 tres totales reales | Verificado. Valores máximos mediante mocks; sin impuestos, descuentos ni precios calculados en navegador |
| Contrato: esquema 1, UUID, producto/cantidad coincidentes, versiones y UTC estrictos | [OpenAPI](openapi.json), `P05ConsultaTarifa.consultar` | [Pruebas de contrato](../proveedor/test/contract.test.ts); `rejectsInconsistentFields`, `rejectsInvalidVersionsAndQuantityTypes` en E5 | Verificado. Se rechazan cuerpo/tipos/campos incoherentes; errores de infraestructura pueden no ser JSON |
| Autenticación: API key protegida, sin secretos en UI/Apex | [Conexión](CONEXION.md), External/Named Credential, autenticación previa al cuerpo | E1 200→401→200; pruebas de clave ausente/incorrecta en [proveedor](../proveedor/test/app.test.ts); E5B prueba 1/0/1 | Verificado por capas. Los 401 Salesforce de E5/E5B son inducidos tras autenticar, no nuevas sustituciones de clave |
| Permisos: mínimo privilegio, autorización funcional, CRUD/FLS y usuario actual | [Servicio](../salesforce/force-app/main/default/classes/P05TarifasServicio.cls), tres Permission Sets, Custom Permission | `rejectsMissingFunctionalObjectAndFieldPermissions` en E5; E4 `commercial`, E5 `permissions` | Verificado. Perfil de demostración, no usuarios reales de negocio ni auditoría de producción |
| Guardado: una instantánea válida nueva por consulta satisfactoria; campos de servidor | `consultarYGuardar`, `insert as user`, contexto privado y relectura | `savesAllFieldsAsCurrentUser`, `saveDelegatesAndReturnsTopLevelDto` en E5; E3 P05-000000, E4 P05-000001, E5 P05-000002–000004 | Verificado. Nueva acción exitosa crea otra fila; no hay idempotencia entre acciones separadas |
| Integridad: impedir alta directa, edición, borrado y recuperación; conservar copias | Servicio y [trigger](../salesforce/force-app/main/default/triggers/P05ConsultaTarifaIntegridad.trigger), lookup SetNull | `rejectsDirectInsertAndUserUpdatesDeletes`, `integrityRejectsSystemWritesAndSurvivesProductDeletion`, `productChangeDoesNotChangeHistoricalCopies` en E5 | Verificado. Un administrador capaz de cambiar código puede alterar los controles; no es archivo inviolable |
| Fallo de guardado: rollback y ausencia de falso éxito | Savepoint después del callout; finally limpia contexto | `insertionFailureHasNoFalseSuccessOrLeakedPermit`, `providerErrorsCreateNoRows` en E5 | Verificado mediante pruebas Apex; no se provoca corrupción en datos de demostración |
| Histórico propio y detalle: sin proveedor, también caducado | `listarPropias`/`obtener`, OwnerId y USER_MODE; LWC lista 50 | `historyEnforcesOwnerAndStableOrderWithoutCallouts`, `expiredHistoryRemainsReadableWithoutCallout` en E5; E4/E5 `offline`, E5 `serviceOffline` | Verificado. Servicio permite 1–100; UI 50. Acceso administrativo directo queda fuera del filtro del servicio |
| Caducidad: 24 h exactas, emisión futura ≤1000 ms, sin gracia al vencer ni guardar | `validateTimes`, `validateAtSave`, `validarIntegridad` | `temporalBoundariesPreserveExactDurationAndExpiry`, `rejectsExpiryAtSaveEvenIfValidAtReceipt` en E5; fallos reales `expired`/`future` | Verificado. Fronteras y carrera de guardado deterministas; no espera física de 24 h ni carrera DML real |
| Interfaz: entrada P05, confirmación, detalle, errores seguros y vigencia estimada | [LWC](../salesforce/force-app/main/default/lwc/p05Tarifas/p05Tarifas.js), DTO y controlador | E4 `ui`; E5 30 Jest y recorrido comercial; `resume.visibleValidityEvidence` | Verificado. Reanudación «Vigente» confirmada visualmente; texto no capturado automáticamente. DateTime persistido en segundos y estimación con incertidumbre |
| Errores: categorías seguras, timeout, sin instantáneas ni éxito anterior | `safeError`, `safeMessage`, timeout 10 s; sin reintento propio | `mapsHttpErrorsWithoutTrustingBody`, `mapsTimeoutAndConnectionErrors`, `allKnownErrorsAreSafeAndUnknownDetailsAreHidden`; E5 `serviceReal`, ocho `commercialFailures` | Verificado. Desconexión vía túnel devuelve HTTP_ERROR; timeout HTTP local separado del real Salesforce |
| Recuperación: controles reutilizables y nuevo éxito; histórico intacto | Estado LWC y servicio síncrono | Jest de recuperación; [HTTP real](../proveedor/test/fault-http.test.ts); E5 `commercialRecovery`, `snapshots` | Verificado: P05-000004 posterior a los fallos. E5B conserva las cinco filas sin DML |
| Ausencia de reintentos automáticos | Un `Http.send` por invocación; una llamada LWC con bloqueo mientras guarda | E5B `matrix`: un callout por operación y dos entradas 429/503; controles Node una | A demostrada y aceptada; B no garantizada. Delimitación aceptada el 19/11/2026 según el registro siguiente |

## Aceptación del transporte — 19/11/2026

La regla inicial de [PROJECT_BRIEF](PROJECT_BRIEF.md) en `603ebd1` dice «Sin
reintentos automáticos; timeout Apex inicial de diez segundos». No especifica una
garantía técnica de entrega física única. El estado de fase 5 introdujo expresamente
ese criterio pendiente al detectar repeticiones; [5B](FASE-5B.md) lo delimitó sin
aceptarlo. El cierre actual acepta expresamente la delimitación siguiente y conserva
esa trazabilidad; no modifica retrospectivamente el diagnóstico.

- **A — demostrada:** ausencia de reintentos programados en la aplicación. Una
  invocación del cliente produce un callout Apex; el bloqueo UI evita otro envío
  mientras la operación está pendiente.
- **B — no garantizada:** una sola recepción física en todo el transporte. En 5B
  hubo dos entradas distintas ante 429/503, con una recepción en los controles
  Node correspondientes. El componente externo causante no está identificado.
  No se demostró reintento propio y las sondas no modificaron instantáneas.

**Alcance aceptado para V1:**

> La V1 garantiza ausencia de reintentos programados en el código de la aplicación.
> Se acepta como limitación conocida que el recorrido externo probado puede producir
> dos recepciones ante HTTP 429/503 por un único callout Apex, sin componente interno
> identificado. No se garantiza entrega física única ni idempotencia entre acciones
> separadas. El hallazgo y sus evidencias se conservan sin cambios.

Esta limitación está aceptada y no constituye una tarea obligatoria pendiente de
V1. No se introduce una solución fuera de alcance ni se atribuye la causa a una
plataforma concreta. El cierre no requiere repetir el diagnóstico ni contactar soporte.

<a id="instalacion"></a>
## Instalación y alcance comprobado

| Estado | Fuente y conclusión |
| --- | --- |
| Incremental ejecutada | E3 25 componentes/29 Apex, E4 nueve/36, E5 ocho/40; instalación en el P05 existente |
| Limpia documentada | [INSTALACION](INSTALACION.md) y [v1.xml](../salesforce/manifest/v1.xml); referencias y dependencias revisadas estáticamente en fase 6 |
| Limpia realmente ejecutada | **No**. Tampoco se ejecuta conversión local como sustituto de esa evidencia |

Las reglas originales del brief (`603ebd1`) no enumeran instalación limpia como
requisito de aceptación. [Fase 3](FASE-3.md), [fase 4](FASE-4.md),
[estado de fase 5](ESTADO-FASE-5.md) y [estado de fase 5B](ESTADO-FASE-5B.md) la
registran como límite o comprobación pendiente, sin una aprobación específica de
una nueva instalación. No se ha localizado una fuente del proyecto que la convierta
en condición obligatoria ya aprobada. Esta conclusión se limita a esas fuentes.

**Decisión aceptada el 19/11/2026:** despliegue incremental comprobado e instalación
desde cero documentada y revisada estáticamente, pero no ejecutada. La falta de
ejecución limpia queda aceptada como limitación de verificación, sin constituir
una tarea obligatoria pendiente de V1. Una ampliación posterior requiere nuevo encargo.

## Defectos, límites y decisión de cierre

En la revisión estática de fase 6 no se identificó un defecto funcional nuevo;
no equivalía a una suite nueva ni demostraba ausencia universal de defectos.
Aquella revisión corrigió la instrucción documental de instalación obsoleta e
incorporó el manifiesto completo: desplegar todas las clases antes del esquema
ya no era un orden válido. El cierre actual no modifica esos archivos operativos.

Límites conocidos: transporte anterior, instalación limpia sin ejecutar, proveedor
y catálogo simulados, UI de escritorio, histórico acotado, resolución temporal y
estimación, ausencia de idempotencia entre acciones y de controles de producción
fuera del alcance. No se exigen como funcionalidades nuevas de V1.

El alcance funcional, las evidencias revisadas y las dos delimitaciones anteriores
quedan aceptados el **19/11/2026**. **V1 queda cerrada definitivamente dentro de
este alcance.** Las limitaciones se conservan y no son tareas obligatorias pendientes
de esta versión. El cierre no acredita entrega física única, instalación limpia
ejecutada ni pruebas nuevas. Su aceptación actual y la publicación posterior de
esta actualización documental son hechos distintos.
