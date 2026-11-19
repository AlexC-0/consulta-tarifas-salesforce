# P05 — Consulta de tarifas
Trabajar exclusivamente en este repositorio. No inspeccionar ni modificar P01–P04.
No ejecutar staging, commit ni push; dejar los cambios preparados para revisión.
No modificar el remoto ni reescribir el historial.
Antes de editar: comprobar ruta, instrucciones, raíz, rama, remoto y estado Git.
Leer README.md, docs/PROJECT_BRIEF.md, docs/STATUS.md y docs/ENVIRONMENT.md.
Conservar cambios previos. Documentación principalmente en castellano.
Documentar únicamente objetivos, configuración, funcionalidades, decisiones,
cambios, comprobaciones y limitaciones del proyecto. Utilizar redacción técnica
directa. Excluir relatos de conversaciones, asignaciones personales, firmas
automáticas y detalles internos de elaboración.

Mantenimiento de V1 cerrada y aceptada el 19/11/2026.
Estado: V1 completada y aceptada dentro del alcance documentado, con limitaciones conocidas.
Revisión final publicada en 061485df3455dab9296950a7bdf5df33630ab069;
diagnóstico en 756e931dbb2e78f4d3bdf64c762738f71344e976 e implementación funcional
en 3f6a4dcd9aa08ce3884a78ef9dc252cf684ede16.
Conservar diagnóstico, resultados y JSON históricos sin atribuirles la aceptación
posterior. El registro del cierre es documental; su publicación es un paso separado.
No atribuir causas internas sin evidencia. Ampliaciones y operaciones posteriores
requieren un nuevo encargo; no convertir limitaciones aceptadas en tareas pendientes.
No ejecutar suites, servicios, túneles, Login As, despliegues ni llamadas externas
para registrar este cierre. No contactar soporte, crear organizaciones ni reinicializar datos.
Actualizar únicamente documentación; no modificar código, pruebas, manifiestos,
dependencias, contrato, permisos, datos ni configuración funcional.
Conservar funcionalidades, USER_MODE,
permisos e integridad. Emisión futura: margen fijo máximo de 1000 ms; caducidad sin
tolerancia y duración exacta de 24 horas. No cambiar relojes ni configuración NTP.
Sin ampliaciones comerciales ni inicio del P06.
Fase 3 publicada en 148d0e0; conservar históricos y P05-000000.
No acceder a Gmail. No imprimir secretos, tokens, archivos de autenticación ni URLs
reutilizables de acceso. No reutilizar organizaciones ajenas o destinos implícitos.
La creación o identificación de la organización P05, el login y la introducción
del secreto requieren intervención manual; no automatizar estas operaciones.
Verificar identidad del destino antes de desplegar; destino explícito en cada comando.
No instalar/actualizar herramientas globales ni cambiar su configuración.
Antes de abrir un túnel público, presentar servicio, puerto, duración y finalidad
y obtener confirmación expresa. Servicio exclusivamente en loopback.
Sin servicios de pago, comunicaciones reales ni nuevos privilegios amplios.
Separar pruebas por inyección, HTTP local, mocks Apex y callout real Salesforce.
No atribuir éxito a pruebas no ejecutadas. Conservar instantáneas válidas de demostración. No borrar datos anteriores.

Fase 4 completada: nueve componentes, 36/36 Apex y 21/21 Jest. Recorrido comercial
real, P05-000001 conservada junto con P05-000000, detalle ajeno denegado e histórico
sin proveedor comprobados. Login As restaurado false; cuenta comercial mínima
conservada. Fase 4 publicada en df23ec6. Ver docs/STATUS.md y docs/USO.md.
Las autorizaciones anteriores de pruebas, túneles y despliegues son históricas;
no habilitan operaciones nuevas ni representan trabajos pendientes de ejecución.
No crear organizaciones ni usuarios persistentes. Conservar credenciales e instantáneas.
Fase 5 desplegada incrementalmente: 40/40 Apex, 30/30 Jest, 43/43 proveedor.
P05-000000 a P05-000004 conservadas. Proveedor/túnel cerrados, endpoint inicial
y Login As=false restaurados. Ver docs/STATUS.md y docs/evidencias-fase-5.json.
Fase 5B: 14 operaciones A/B/C, 18 entradas HTTP independientes. A/B: una entrada
por estado; C 429/503: dos por un callout, confirmadas una vez por estado. Tramo
externo de Apex acotado, componente interno sin identificar. Sin defecto propio
demostrado. TypeScript y 3/3 pruebas afectadas correctos; sin despliegue de aplicación.
Cinco instantáneas intactas, endpoint restaurado, procesos propios detenidos en
3,78 minutos de túnel autorizado; Login As no utilizado. Ver docs/FASE-5B.md.
Aceptado para V1: ausencia de reintentos programados en la aplicación, sin garantía
de entrega física única ni idempotencia entre acciones separadas. Se conservan las
dos recepciones ante 429/503 por callout Apex y el componente externo sin identificar.
Aceptado: despliegue incremental comprobado e instalación limpia documentada y
revisada estáticamente, pero no ejecutada. No son tareas obligatorias pendientes
de V1. No añadir idempotencia ni reintentos para ocultar el hallazgo.
