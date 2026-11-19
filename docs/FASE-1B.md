# Estado — fase 1B completada, 19/11/2026

Demostrado: **Apex P05 → Named Credential → HTTPS → proveedor autenticado**.
Éxito, rechazo de clave incorrecta y éxito tras restauración, con correlación de
requestId en los tres casos. No se declara V1 terminada: LWC, instantáneas, tres
productos y permisos de comerciales siguen fuera de esta fase.

## Base y alcance

Base del proveedor y la sonda Apex: `603ebd1a016b849453c0866955ebe711bf090565`.

## Base local de fase 1: evidencia reutilizada

- TypeScript correcto y 27/27 pruebas Node/Fastify por inyección.
- HTTP loopback real: health 200, tarifa 200, clave ausente/incorrecta 401.
- Correlación local histórica: `1362d430-a0c5-4516-adba-623103984f0c`, total 59.70 EUR.
- Contrato OpenAPI contrastado con petición y respuestas 200/401 usando Ajv.
- Auditoría de dependencias de ejecución: cero vulnerabilidades notificadas.
- cloudflared portable 2026.11.1 con SHA256 oficial verificado.

El proveedor no cambió en fase 1B, por lo que no se repitieron por rutina
sus 27 pruebas ni el smoke. Esas cifras no se atribuyen a una ejecución nueva.

## Organización y entorno real

Playground gratuito **P05 Consulta Tarifas** creado desde Trailhead, con
credenciales específicas de P05 y acceso comprobado.

CLI autenticada con alias explícito `p05-tarifas-dev`, sin cambiar destinos
predeterminados. La consulta de Organization coincidió con el ID de la tarjeta
P05 de Trailhead. Developer Edition, IsSandbox=false. IDs privados, usuario y
dominio no se versionan.

El destino devolvió API **68.0** tanto en consulta pública como autenticada.
Se materializaron sfdx-project.json y los dos cls-meta.xml con el script existente.
La demostración se ejecutó con perfil **System Administrator**, UserType Standard.
No acredita todavía acceso de un comercial ordinario.

Las comprobaciones de navegador utilizaron Playwright CLI 0.1.25 instalado solo
en .local/browser-tools, sin actualizar herramientas globales ni cambiar PATH.

## Despliegues y correcciones

| Operación | Resultado |
| --- | --- |
| Primer despliegue de dos clases | Falló: currency es identificador reservado; cero pruebas ejecutadas |
| Corrección y despliegue de clases | Succeeded: 2 componentes, 0 errores |
| P05ConsultaTarifaTest | **8 métodos ejecutados, 8 aprobados, 0 fallidos** |
| Primer despliegue de conexión | Falló por secuencia obligatoria ausente en AuthHeader |
| Corrección y despliegue de conexión | Succeeded: 3 componentes, 0 errores |
| Asignación de P05_Conexion_Proveedor | Correcta al usuario administrador de la demostración |

El campo interno Apex pasó a currencyCode; el contrato JSON mantiene currency.
Se actualizaron cliente, test y script de demostración. No se debilitó la validación.
AuthHeader X-API-Key incluye sequenceNumber=1.

Metadatos de conexión: External Credential Custom P05_Proveedor_Externo,
principal P05_Compartido, Named Credential SecuredEndpoint P05_Proveedor y
Permission Set P05_Conexion_Proveedor. Este concede únicamente acceso al principal
y a P05ConsultaTarifa; no incorpora permisos generales ni CRUD de objetos.
La URL temporal se materializa solo en .local; la clave se almacena cifrada en
el parámetro ApiKey y no forma parte de metadata.

## Diagnóstico del primer callout

El proveedor devolvía 200, pero Apex rechazaba INVALID_RESPONSE porque Windows
estaba adelantado unos 2,08 s. El diagnóstico comparó únicamente campos de tarifa
y tiempos: vigencia exacta de 24 h, importes y correlación correctos; emisión
2046 ms posterior a la recepción según Salesforce.

Windows Time figuraba sin sincronizar, con origen Local CMOS Clock. Una consulta
a time.windows.com confirmó aproximadamente -2,081 s. La resincronización puntual
mediante w32tm /resync /rediscover terminó con código 0.
Medidas posteriores: +0,0057 / +0,0022 / +0,0026 s.
No se cambiaron servidores NTP ni configuración persistente de hora.
La comprobación de emisiones futuras y caducidad permanece intacta.

## Evidencia real HTTPS

| Caso | Resultado Apex | HTTP proveedor | requestId |
| --- | --- | --- | --- |
| Clave válida | Éxito, 200 | 200 | 2d40136d-1cc7-4889-89c9-95ac9dad55fb |
| Clave incorrecta | UNAUTHORIZED | 401 | baea7d34-6f9f-4d6d-a920-c14f3def3727 |
| Clave válida restaurada | Éxito, 200 | 200 | 160d98e0-6626-458b-899b-888dd70ad372 |

Ambos éxitos: PROD-001, cantidad 3, EUR, unitario 19.90 y total 59.70;
UUID válidos y vigencia exacta de 24 horas. Cada requestId coincide con el log
del proveedor. Evidencia completa, limitada a campos no sensibles, en
[evidencias-fase-1b.json](evidencias-fase-1b.json).

Son ejecuciones del script consulta-demo.apex fuera de Test, no HttpCalloutMock,
curl ni navegador. El 401 produjo fallo controlado de Apex, no un éxito aparente.

## Credenciales, restauración y cierre

La clave local se cargó en el parámetro protegido mediante un
helper local que transmite la clave por stdin a la API oficial, sin imprimirla,
pasarla en argumentos ni incrustarla en código o metadata versionados.
La sustitución negativa se protegió con finally para restaurar la clave.
Una nueva llamada 200 confirmó la restauración.

El Quick Tunnel se limitó a 127.0.0.1:3055 durante la demostración.
Se verificó el binding exclusivo a loopback. Al terminar se detuvieron los dos
procesos propios comprobando sus PID y ejecutables; **cero listeners en 3055**.
La clave válida permanece en .env ignorado y en el parámetro cifrado de P05.
Las credenciales y el Permission Set mínimo quedan configurados para el proyecto.

Se conservan los originales y la evidencia saneada. No se versionan secretos,
URLs temporales, IDs privados, archivos de autenticación ni debug logs completos.
Al finalizar la fase 1B se revisaron enlaces, XML/JSON, espacios y exclusiones,
y se comparó en memoria la clave contra los 32 archivos versionables, sin mostrarla.
Se comprobaron seis JSON, cinco XML/plantillas, tres scripts PowerShell y nueve
enlaces relativos. La conversión local final de fuentes DX terminó con estado 0.
Se conservaron originales, herramientas y evidencia saneada.

## Criterios de fase 1B

Organización verificada, DX compatible, clases desplegadas, 8/8 mocks, callout
real correlacionado, rechazo 401, restauración, cierre y documentación: satisfechos.
LWC, instantáneas y permisos comerciales quedaron fuera de esta fase.
Su evolución se documenta en [STATUS](STATUS.md).
