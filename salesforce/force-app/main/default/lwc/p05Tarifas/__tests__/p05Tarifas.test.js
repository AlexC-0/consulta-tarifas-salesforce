import { createElement } from 'lwc';
import P05Tarifas from 'c/p05Tarifas';
import listarProductos from '@salesforce/apex/P05TarifasControlador.listarProductos';
import consultarYGuardar from '@salesforce/apex/P05TarifasControlador.consultarYGuardar';
import listarPropias from '@salesforce/apex/P05TarifasControlador.listarPropias';
import obtener from '@salesforce/apex/P05TarifasControlador.obtener';
import obtenerHora from '@salesforce/apex/P05TarifasControlador.obtenerHora';
jest.mock('@salesforce/apex/P05TarifasControlador.obtenerHora',()=>({default:jest.fn()}),{virtual:true});
jest.mock('@salesforce/apex/P05TarifasControlador.listarProductos',()=>({default:jest.fn()}),{virtual:true});
jest.mock('@salesforce/apex/P05TarifasControlador.consultarYGuardar',()=>({default:jest.fn()}),{virtual:true});
jest.mock('@salesforce/apex/P05TarifasControlador.listarPropias',()=>({default:jest.fn()}),{virtual:true});
jest.mock('@salesforce/apex/P05TarifasControlador.obtener',()=>({default:jest.fn()}),{virtual:true});
const flush=async()=>{for(let i=0;i<10;i++)await Promise.resolve();};
const deferred=()=>{let resolve,reject;const promise=new Promise((a,b)=>{resolve=a;reject=b;});return {promise,resolve,reject};};
const quote=(id='one')=>({recordId:id,reference:'P05-'+id,productName:'Producto de prueba',productCode:'PROD-001',
quantity:3,unitPrice:19.9,totalPrice:59.7,currencyCode:'EUR',createdAt:'2026-11-19T10:00:00.000Z',
issuedAt:'2026-11-19T10:00:00.000Z',validUntil:'2026-11-20T10:00:00.000Z',serverNow:'2026-11-19T12:00:00.000Z',
notice:'Información obtenida en esta consulta; no se actualiza automáticamente'});
let el;
const root=()=>el.shadowRoot;
const clickSave=()=>root().querySelector('[data-action="save"]').click();
const select=(quantity='3')=>{
 const combo=root().querySelector('lightning-combobox');combo.dispatchEvent(new CustomEvent('change',{detail:{value:'product-id'}}));
 const input=root().querySelector('lightning-input');input.value=quantity;input.dispatchEvent(new CustomEvent('change'));
};
const row=(id)=>root().querySelector('lightning-datatable').dispatchEvent(new CustomEvent('rowaction',{detail:{action:{name:'open'},row:{recordId:id}}}));
const mount=async()=>{el=createElement('c-p05-tarifas',{is:P05Tarifas});document.body.appendChild(el);await flush();};
beforeEach(()=>{
 jest.useFakeTimers();jest.setSystemTime(new Date('2026-11-19T12:00:00Z'));
 obtenerHora.mockResolvedValue('2026-11-19T12:00:00.000Z');
 listarProductos.mockResolvedValue([{productId:'product-id',name:'Producto de prueba',code:'PROD-001'}]);
 listarPropias.mockResolvedValue([]);consultarYGuardar.mockResolvedValue(quote());obtener.mockResolvedValue(quote('old'));
});
afterEach(()=>{while(document.body.firstChild)document.body.removeChild(document.body.firstChild);jest.clearAllMocks();jest.useRealTimers();});
test('carga productos con nombre y código y muestra histórico vacío',async()=>{
 await mount();expect(root().querySelector('lightning-combobox').options).toEqual([{label:'Producto de prueba · PROD-001',value:'product-id'}]);
 expect(root().textContent).toContain('Todavía no tienes');expect(consultarYGuardar).not.toHaveBeenCalled();
});
test('catálogo vacío deshabilita envío',async()=>{
 listarProductos.mockResolvedValue([]);await mount();expect(root().textContent).toContain('No hay productos disponibles');
 expect(root().querySelector('[data-action="save"]').disabled).toBe(true);
});
test.each(['','0','-1','1.5','10001'])('cantidad inválida %s no envía',async value=>{
 await mount();select(value);clickSave();await flush();expect(consultarYGuardar).not.toHaveBeenCalled();
 expect(root().querySelector('[data-message="form-error"]').textContent).toContain('entera');
});
test('producto obligatorio sin envío',async()=>{await mount();clickSave();await flush();expect(consultarYGuardar).not.toHaveBeenCalled();});
test('envía solo producto y cantidad, confirma persistencia y formato monetario',async()=>{
 await mount();select();clickSave();await flush();expect(consultarYGuardar).toHaveBeenCalledWith({productId:'product-id',quantity:3});
 expect(root().querySelector('[data-message="confirmation"]').textContent).toContain('P05-one guardada');
 const nums=root().querySelectorAll('lightning-formatted-number');expect(nums).toHaveLength(2);
 expect(Number(nums[0].minimumFractionDigits)).toBe(2);expect(Number(nums[1].maximumFractionDigits)).toBe(2);
 expect(root().textContent).toContain(quote().notice);expect(root().textContent).toContain('Zona horaria');
});
test('doble clic conserva una sola operación pendiente',async()=>{
 const pending=deferred();consultarYGuardar.mockReturnValue(pending.promise);await mount();select();clickSave();clickSave();await flush();
 expect(consultarYGuardar).toHaveBeenCalledTimes(1);expect(root().querySelector('[data-action="save"]').disabled).toBe(true);
 pending.resolve(quote());await flush();expect(root().querySelector('[data-action="save"]').disabled).toBe(false);
});
test('error conocido muestra mensaje saneado y referencia y recupera controles',async()=>{
 consultarYGuardar.mockRejectedValue({body:{message:JSON.stringify({kind:'P05',code:'TIMEOUT',message:'El proveedor ha tardado demasiado.',requestId:'11111111-1111-4111-8111-111111111111'})}});
 await mount();select();clickSave();await flush();expect(root().textContent).toContain('El proveedor ha tardado demasiado.');
 expect(root().textContent).toContain('11111111-1111-4111-8111-111111111111');
 expect(root().querySelector('[data-action="save"]').disabled).toBe(false);
});
test('fallo inesperado no expone detalles ni reintenta',async()=>{
 consultarYGuardar.mockRejectedValue({body:{message:'private stack token-value'}});await mount();select();clickSave();await flush();
 expect(root().textContent).not.toContain('private');expect(root().textContent).not.toContain('token-value');
 expect(root().textContent).toContain('Revisa Mis consultas');expect(consultarYGuardar).toHaveBeenCalledTimes(1);
});
test('nuevo error no conserva un éxito anterior como resultado nuevo',async()=>{
 await mount();select();clickSave();await flush();expect(root().textContent).toContain('P05-one guardada');
 consultarYGuardar.mockRejectedValue(new Error('private'));clickSave();await flush();
 expect(root().querySelector('[data-message="confirmation"]').textContent).toBe('');
 expect(root().textContent).not.toContain('Tarifa guardada:');expect(root().textContent).not.toContain('P05-one guardada');
});
test('guardado confirmado sobrevive al error de refresco',async()=>{
 await mount();listarPropias.mockRejectedValue(new Error('read failed'));select();clickSave();await flush();
 expect(root().querySelector('[data-message="confirmation"]').textContent).toContain('guardada');
 expect(root().querySelector('[data-message="history-error"]')).not.toBeNull();
 expect(root().querySelector('[data-message="form-error"]')).toBeNull();
});
test('histórico y detalle son lecturas, sin guardado',async()=>{
 listarPropias.mockResolvedValue([quote('old')]);await mount();row('old');await flush();
 expect(obtener).toHaveBeenCalledWith({recordId:'old'});expect(root().textContent).toContain('Detalle histórico: P05-old');
 root().querySelector('[data-action="refresh"]').click();await flush();expect(consultarYGuardar).not.toHaveBeenCalled();
});
test('detalle tardío no pisa selección posterior',async()=>{
 listarPropias.mockResolvedValue([quote('a'),quote('b')]);const a=deferred(),b=deferred();obtener.mockReturnValueOnce(a.promise).mockReturnValueOnce(b.promise);
 await mount();row('a');row('b');b.resolve(quote('b'));await flush();a.resolve(quote('a'));await flush();
 expect(root().textContent).toContain('Detalle histórico: P05-b');expect(root().textContent).not.toContain('Detalle histórico: P05-a');
});
test('respuesta de guardado tardía confirma referencia sin pisar detalle seleccionado',async()=>{
 listarPropias.mockResolvedValue([quote('old')]);const pending=deferred();consultarYGuardar.mockReturnValue(pending.promise);
 await mount();select();clickSave();row('old');await flush();pending.resolve(quote('new'));await flush();
 expect(root().textContent).toContain('P05-new guardada');expect(root().textContent).toContain('Detalle histórico: P05-old');
});
test('refresco reemplaza filas sin duplicarlas',async()=>{
 listarPropias.mockResolvedValue([quote()]);await mount();select();clickSave();await flush();
 expect(root().querySelector('lightning-datatable').data).toHaveLength(1);
});
test('vigencia cambia con la caducidad sin consultas externas',async()=>{
 consultarYGuardar.mockResolvedValue({...quote(),serverNow:'2026-11-20T09:59:59.000Z'});
 await mount();select();clickSave();await flush();expect(root().querySelector('[data-message="validity"]').textContent).toBe('Vigente');
 jest.advanceTimersByTime(1000);await flush();
 expect(root().querySelector('[data-message="validity"]').textContent).toBe('Caducada');
 expect(consultarYGuardar).toHaveBeenCalledTimes(1);
 expect(obtenerHora).not.toHaveBeenCalled();
});
test.each(['2020-01-01','2040-01-01'])('reloj local %s no determina vigencia histórica',async localTime=>{
 jest.setSystemTime(new Date(localTime));listarPropias.mockResolvedValue([quote('old')]);
 await mount();row('old');await flush();expect(root().querySelector('[data-message="validity"]').textContent).toBe('Vigente');
 jest.setSystemTime(new Date('2050-01-01'));jest.advanceTimersByTime(1000);await flush();
 expect(root().querySelector('[data-message="validity"]').textContent).toBe('Vigente');
 expect(consultarYGuardar).not.toHaveBeenCalled();
});
test('latencia próxima a caducidad no presenta vigencia falsa',async()=>{
 const pending=deferred();consultarYGuardar.mockReturnValue(pending.promise);
 await mount();select();clickSave();jest.advanceTimersByTime(2000);
 pending.resolve({...quote(),serverNow:'2026-11-20T09:59:59.000Z'});await flush();
 expect(root().querySelector('[data-message="validity"]').textContent).toContain('pendiente');
 jest.advanceTimersByTime(1000);await flush();expect(root().querySelector('[data-message="validity"]').textContent).toBe('Caducada');
});
test('reanudar invalida referencia, deduplica y consulta solo Salesforce',async()=>{
 await mount();select();clickSave();await flush();const pending=deferred();obtenerHora.mockReturnValue(pending.promise);
 window.dispatchEvent(new Event('focus'));window.dispatchEvent(new Event('pageshow'));await flush();
 expect(root().querySelector('[data-message="validity"]').textContent).toContain('pendiente');
 expect(obtenerHora).toHaveBeenCalledTimes(1);pending.resolve('2026-11-20T10:00:00.000Z');await flush();
 expect(root().querySelector('[data-message="validity"]').textContent).toBe('Caducada');
 expect(consultarYGuardar).toHaveBeenCalledTimes(1);
});
test('fallo de referencia conserva confirmación sin reintentos',async()=>{
 await mount();select();clickSave();await flush();obtenerHora.mockRejectedValue(new Error('private'));
 window.dispatchEvent(new Event('focus'));await flush();jest.advanceTimersByTime(3000);await flush();
 expect(root().querySelector('[data-message="validity"]').textContent).toContain('pendiente');
 expect(root().textContent).toContain('P05-one guardada');expect(root().textContent).not.toContain('private');
 expect(obtenerHora).toHaveBeenCalledTimes(1);
});
test('referencia tardía no sustituye la de un nuevo detalle',async()=>{
 listarPropias.mockResolvedValue([quote('old')]);await mount();row('old');await flush();
 const pending=deferred();obtenerHora.mockReturnValue(pending.promise);window.dispatchEvent(new Event('focus'));
 row('old');await flush();pending.resolve('2026-11-21T12:00:00Z');await flush();
 expect(root().querySelector('[data-message="validity"]').textContent).toBe('Vigente');
});
test('desconexión elimina listeners y descarta hora pendiente',async()=>{
 await mount();select();clickSave();await flush();const pending=deferred();obtenerHora.mockReturnValue(pending.promise);
 window.dispatchEvent(new Event('focus'));document.body.removeChild(el);pending.resolve('2026-11-21T12:00:00Z');await flush();
 window.dispatchEvent(new Event('focus'));document.dispatchEvent(new Event('visibilitychange'));
 expect(obtenerHora).toHaveBeenCalledTimes(1);expect(jest.getTimerCount()).toBe(0);
});
test('vista oculta invalida hora y vuelve a obtenerla al hacerse visible',async()=>{
 await mount();select();clickSave();await flush();
 const visibility=jest.spyOn(document,'visibilityState','get').mockReturnValue('hidden');
 document.dispatchEvent(new Event('visibilitychange'));await flush();
 expect(root().querySelector('[data-message="validity"]').textContent).toContain('pendiente');
 expect(obtenerHora).not.toHaveBeenCalled();visibility.mockReturnValue('visible');
 obtenerHora.mockResolvedValue('2026-11-20T10:00:00Z');document.dispatchEvent(new Event('visibilitychange'));await flush();
 expect(root().querySelector('[data-message="validity"]').textContent).toBe('Caducada');visibility.mockRestore();
});
test('pausa larga de temporizadores exige otra referencia Salesforce',async()=>{
 await mount();select();clickSave();await flush();const clock=jest.spyOn(performance,'now').mockReturnValue(60_000);
 obtenerHora.mockResolvedValue('2026-11-20T10:00:00Z');jest.advanceTimersByTime(1000);await flush();
 expect(obtenerHora).toHaveBeenCalledTimes(1);
 expect(root().querySelector('[data-message="validity"]').textContent).toBe('Caducada');clock.mockRestore();
});
test('errores independientes de productos e histórico',async()=>{
 listarProductos.mockRejectedValue(new Error('secret'));listarPropias.mockRejectedValue(new Error('secret'));
 await mount();expect(root().textContent).toContain('No se pudieron cargar los productos');
 expect(root().textContent).toContain('No se pudo actualizar el histórico');expect(root().textContent).not.toContain('secret');
});
test('desmontar ignora respuestas tardías y limpia temporizador',async()=>{
 const pending=deferred();listarProductos.mockReturnValue(pending.promise);await mount();document.body.removeChild(el);
 pending.resolve([]);await flush();expect(jest.getTimerCount()).toBe(0);
});
