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

Fase 6: revisión documental y preparación de la aceptación V1, sobre fase 5B
publicada en 756e931dbb2e78f4d3bdf64c762738f71344e976. Implementación funcional
publicada en 3f6a4dcd9aa08ce3884a78ef9dc252cf684ede16.
Estado: implementación y diagnóstico completados; aceptación final pendiente.
Contrastar criterios, código, evidencias y reproducción sin añadir funcionalidades.
Conservar íntegro el diagnóstico 5B y distinguir evidencias históricas de revisión
estática. Proponer ausencia de reintentos de aplicación sin dar por aceptada la
delimitación del transporte. No atribuir causas internas sin evidencia.
No ejecutar suites, servicios, túneles, Login As, despliegues ni llamadas externas
en esta fase. No contactar soporte, crear organizaciones ni reinicializar datos.
Se permiten documentación y manifiestos acotados revisados estáticamente.
Conservar funcionalidades, USER_MODE,
permisos e integridad. Emisión futura: margen fijo máximo de 1000 ms; caducidad sin
tolerancia y duración exacta de 24 horas. No cambiar relojes ni configuración NTP.
Sin ampliaciones comerciales ni cierre definitivo V1 antes de revisión.
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
La autorización de despliegue y demostración de fase 5 es histórica; no habilita
operaciones nuevas en fase 6. No crear organizaciones ni usuarios persistentes.
Conservar credenciales e instantáneas. V1 no cerrada.
Fase 5 desplegada incrementalmente: 40/40 Apex, 30/30 Jest, 43/43 proveedor.
P05-000000 a P05-000004 conservadas. Proveedor/túnel cerrados, endpoint inicial
y Login As=false restaurados. Ver docs/STATUS.md y docs/evidencias-fase-5.json.
Fase 5B: 14 operaciones A/B/C, 18 entradas HTTP independientes. A/B: una entrada
por estado; C 429/503: dos por un callout, confirmadas una vez por estado. Tramo
externo de Apex acotado, componente interno sin identificar. Sin defecto propio
demostrado. TypeScript y 3/3 pruebas afectadas correctos; sin despliegue de aplicación.
Cinco instantáneas intactas, endpoint restaurado, procesos propios detenidos en
3,78 minutos de túnel autorizado; Login As no utilizado. Ver docs/FASE-5B.md.
Pendiente V1: revisar la garantía de ausencia de reintentos programados sin prometer
entrega única externa; instalación limpia sin comprobar. No añadir idempotencia
ni reintentos para ocultar el hallazgo. Fase 5B publicada en 756e931.
La instalación limpia está documentada pero no ejecutada; no convertir esa
limitación en requisito aprobado sin fuente. No declarar cierre V1 ni iniciar P06.
