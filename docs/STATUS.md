# Estado — fase 6, revisión final, 19/11/2026

**Implementación y diagnóstico completados; aceptación final pendiente.**
La entrega consolida alcance, criterios, evidencias, reproducción y límites de V1.
No registra aceptación de las decisiones pendientes ni declara cierre definitivo.

## Base publicada y alcance de esta revisión

- Fase 5B publicada: **756e931dbb2e78f4d3bdf64c762738f71344e976**.
- Implementación funcional de fase 5: **3f6a4dcd9aa08ce3884a78ef9dc252cf684ede16**.
- Repositorio, raíz, rama main y remoto P05 comprobados; estado inicial limpio.
  Esta entrega de fase 6 queda sin staging, commit ni push.
- Código, contrato OpenAPI, dependencias, datos y configuración funcional sin cambios.
  No se ejecutan suites, servicios, despliegues, Login As ni demostraciones externas.

## Entrega revisable

| Documento | Contenido |
| --- | --- |
| [ACEPTACION-V1](ACEPTACION-V1.md) | Matriz requisito→implementación→evidencia, límites y propuestas pendientes |
| [INSTALACION](INSTALACION.md) | Preparación local, secreto manual, orden de metadata, permisos y demostración |
| [FICHA-V1](FICHA-V1.md) | Problema, arquitectura, decisiones, pruebas y límites del proyecto simulado |
| [v1.xml](../salesforce/manifest/v1.xml) | Inventario completo de fuentes Salesforce, revisado sin desplegar |
| [Evidencia de revisión](evidencias-fase-6.json) | Comprobaciones estáticas de esta fase, separadas de ejecuciones anteriores |

Se corrige el orden documental heredado de desplegar todas las clases antes del
esquema. El procedimiento limpio separa cliente independiente, conexión y conjunto
completo V1, e introduce manualmente el secreto después. También se corrigen la
precondición de fase 4 para el despliegue incremental de fase 5, el número de métodos
Aura (cinco) y las referencias históricas de pruebas y conexión.
No se identifica un defecto funcional nuevo en la revisión estática.

## Evidencias históricas conservadas

| Fase | Alcance y resultados de aquella ejecución |
| --- | --- |
| 1B | Callout administrativo real 200→401→200 y restauración de clave |
| 2 | Tres productos/404 reales; 16 Apex, 42 proveedor |
| 3 | 25 componentes incrementales, 29 Apex; P05-000000 e histórico sin proveedor |
| 4 | Nueve componentes, 36 Apex, 21 Jest; recorrido comercial, aislamiento y P05-000001 |
| 5 | Ocho componentes, 40 Apex, 30 Jest, 43 proveedor; fallos reales, recuperación y P05-000002–000004 |
| 5B | Tres pruebas afectadas y TypeScript; 14 operaciones, seis callouts y 18 entradas; sin DML |

Las cifras no se suman ni se presentan como suites nuevas de fase 6. Mocks, Jest,
inyección, HTTP local, callout administrativo y recorrido comercial se distinguen
en la [matriz final](ACEPTACION-V1.md). El proveedor y los datos son simulados.

El [diagnóstico 5B](FASE-5B.md) y su [JSON](evidencias-fase-5b.json) se conservan
íntegros. El antiguo STATUS se archiva íntegro como [ESTADO-FASE-5B](ESTADO-FASE-5B.md),
con su fecha y contexto anterior a publicación. Sus menciones a cambios aún sin
publicar y el campo histórico workingChangesPublished=false no describen el HEAD
actual. El [estado de fase 5](ESTADO-FASE-5.md) también permanece como antecedente.

## Transporte y aceptación propuesta

5B demuestra una invocación y un callout Apex, con dos recepciones distintas ante
429/503; los controles correspondientes con Node tienen una. No se identifica el
componente externo causante ni se demuestra reintento propio. Las sondas conservan
las cinco instantáneas. No se repite el diagnóstico ni se añade deduplicación.

Propuesta **pendiente de aceptación**: garantizar ausencia de reintentos programados
en la aplicación, conservando la repetición externa como limitación conocida y sin
prometer entrega física única. Texto completo en [ACEPTACION-V1](ACEPTACION-V1.md).
No se atribuye la causa a Salesforce o Cloudflare por separado.

## Instalación y decisiones pendientes

La instalación incremental está comprobada por las fases anteriores. La instalación
limpia dispone ahora de procedimiento y manifiesto revisados estáticamente, pero
**no se ha ejecutado**. No se ejecuta conversión local ni se presenta como sustituto.

El brief original no enumera instalación limpia como criterio aprobado; los estados
posteriores la conservan como limitación. Las [fuentes y conclusión](ACEPTACION-V1.md#instalacion)
delimitan esa lectura. Se propone aceptar el alcance incremental demostrado más
documentación limpia sin ejecución; esa decisión tampoco está aprobada.

Pendientes concretos: aceptar o rechazar la delimitación del transporte, decidir
el alcance de instalación y resolver la aceptación final de V1. La entrega está
preparada para esa decisión, sin iniciar otro proyecto ni ampliar funcionalidades.

## Conservación y comprobaciones de fase 6

Revisión de criterios contra código/tests y claves de evidencia; referencias de
commits y cifras; inventario XML y dependencias del manifiesto; comandos y archivos
de instalación; formatos, enlaces, diff, codificación y ausencia de secretos o
referencias editoriales incompatibles. Detalle en [evidencias-fase-6.json](evidencias-fase-6.json).

No se consulta ni modifica la organización. La última conservación verificada es
la de 5B: P05-000000 a P05-000004 intactas, endpoint restaurado, procesos cerrados,
3,78 minutos de túnel y Login As no utilizado. Son resultados históricos, no una
lectura nueva de estado remoto en fase 6.
