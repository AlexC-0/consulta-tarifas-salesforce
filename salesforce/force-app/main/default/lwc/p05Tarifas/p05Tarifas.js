import { LightningElement } from 'lwc';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import listarProductos from '@salesforce/apex/P05TarifasControlador.listarProductos';
import consultarYGuardar from '@salesforce/apex/P05TarifasControlador.consultarYGuardar';
import listarPropias from '@salesforce/apex/P05TarifasControlador.listarPropias';
import obtener from '@salesforce/apex/P05TarifasControlador.obtener';

const GENERIC = 'No se ha podido confirmar el resultado. Revisa Mis consultas antes de volver a intentarlo.';
const CODES = new Set(['INVALID_REQUEST','PRODUCT_UNAVAILABLE','PRODUCT_NOT_FOUND','ACCESS_DENIED',
    'UNAUTHORIZED','CONNECTION_ERROR','PROVIDER_UNAVAILABLE','INTERNAL_ERROR','RATE_LIMITED',
    'HTTP_ERROR','TIMEOUT','INVALID_RESPONSE','SAVE_FAILED','NOT_FOUND','UNEXPECTED']);
const dateAttributes = { year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',timeZone:TIME_ZONE };
export default class P05Tarifas extends LightningElement {
    productOptions = [];
    productId = '';
    quantity = '1';
    rows = [];
    detail;
    detailKind = '';
    confirmation = '';
    formError = '';
    productError = '';
    historyError = '';
    detailError = '';
    loadingProducts = true;
    loadingHistory = false;
    loadingDetail = false;
    saving = false;
    now = Date.now();
    timeZone = TIME_ZONE;
    _alive = false;
    _detailEpoch = 0;
    _historyEpoch = 0;
    _timer;
    columns = [
        {label:'Referencia',fieldName:'reference',type:'button',typeAttributes:{label:{fieldName:'reference'},name:'open',variant:'base'}},
        {label:'Fecha de consulta',fieldName:'createdAt',type:'date',typeAttributes:dateAttributes},
        {label:'Producto',fieldName:'productName',type:'text',wrapText:true},
        {label:'Cantidad',fieldName:'quantity',type:'number'},
        {label:'Total (EUR)',fieldName:'totalPrice',type:'number',typeAttributes:{minimumFractionDigits:2,maximumFractionDigits:2}},
        {label:'Caducidad',fieldName:'validUntil',type:'date',typeAttributes:dateAttributes}
    ];
    connectedCallback() {
        this._alive = true;
        this._timer = setInterval(() => { this.now = Date.now(); }, 1000);
        this.loadProducts();
        this.refreshHistory();
    }
    disconnectedCallback() {
        this._alive = false;
        this._detailEpoch += 1;
        this._historyEpoch += 1;
        clearInterval(this._timer);
    }
    get submitDisabled() { return this.saving || this.loadingProducts || !this.productOptions.length; }
    get noProducts() { return !this.loadingProducts && !this.productError && !this.productOptions.length; }
    get emptyHistory() { return !this.loadingHistory && !this.historyError && !this.rows.length; }
    get hasRows() { return this.rows.length > 0; }
    get validity() { return Date.parse(this.detail?.validUntil) > this.now ? 'Vigente' : 'Caducada'; }
    get detailHeading() { return this.detailKind === 'saved' ? 'Tarifa guardada' : 'Detalle histórico'; }
    safeMessage(error, fallback = GENERIC) {
        try {
            const body = JSON.parse(error?.body?.message);
            if (body.kind === 'P05' && CODES.has(body.code) && typeof body.message === 'string' && body.message.length <= 240) {
                const ref = /^[a-f0-9-]{36}$/i.test(body.requestId || '') ? ' Referencia de diagnóstico: ' + body.requestId : '';
                return body.message + ref;
            }
        } catch { /* Fallos de transporte o de plataforma: no mostrar detalles externos. */ }
        return fallback;
    }
    async loadProducts() {
        try {
            const products = await listarProductos();
            if (this._alive) this.productOptions = products.map(p => ({label:p.name + ' · ' + p.code,value:p.productId}));
        } catch (error) {
            if (this._alive) this.productError = this.safeMessage(error, 'No se pudieron cargar los productos.');
        } finally { if (this._alive) this.loadingProducts = false; }
    }
    handleProduct(event) { this.productId = event.detail.value; }
    handleQuantity(event) { this.quantity = event.target.value; }
    async handleSave() {
        if (this.saving) return;
        const epoch = ++this._detailEpoch;
        this.confirmation = '';
        this.detail = undefined;
        this.detailError = '';
        this.loadingDetail = false;
        this.formError = '';
        const quantity = Number(this.quantity);
        const valid = this.productId && this.quantity !== '' && Number.isInteger(quantity) && quantity >= 1 && quantity <= 10000;
        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(field => field.reportValidity());
        if (!valid) {
            this.formError = 'Selecciona un producto e introduce una cantidad entera entre 1 y 10.000.';
            return;
        }
        this.saving = true;
        try {
            const saved = await consultarYGuardar({productId:this.productId,quantity});
            if (!this._alive) return;
            this.confirmation = 'Consulta ' + saved.reference + ' guardada.';
            if (epoch === this._detailEpoch) { this.detail = saved; this.detailKind = 'saved'; this.now = Date.now(); }
            // La lectura tiene su propio canal de error: no deshacer la confirmación.
            await this.refreshHistory();
        } catch (error) {
            if (this._alive) this.formError = this.safeMessage(error);
        } finally { if (this._alive) this.saving = false; }
    }
    async refreshHistory() {
        const epoch = ++this._historyEpoch;
        this.loadingHistory = true;
        this.historyError = '';
        try {
            const rows = await listarPropias();
            if (this._alive && epoch === this._historyEpoch) this.rows = rows;
        } catch (error) {
            if (this._alive && epoch === this._historyEpoch) this.historyError = this.safeMessage(error, 'No se pudo actualizar el histórico. La confirmación de guardado, si existe, se conserva.');
        } finally { if (this._alive && epoch === this._historyEpoch) this.loadingHistory = false; }
    }
    async handleRowAction(event) {
        if (event.detail.action.name !== 'open') return;
        const epoch = ++this._detailEpoch;
        this.confirmation = '';
        this.detail = undefined;
        this.detailError = '';
        this.loadingDetail = true;
        try {
            const detail = await obtener({recordId:event.detail.row.recordId});
            if (this._alive && epoch === this._detailEpoch) { this.detail = detail; this.detailKind = 'history'; this.now = Date.now(); }
        } catch (error) {
            if (this._alive && epoch === this._detailEpoch) this.detailError = this.safeMessage(error, 'No se pudo abrir esta consulta histórica.');
        } finally { if (this._alive && epoch === this._detailEpoch) this.loadingDetail = false; }
    }
}
