trigger P05ConsultaTarifaIntegridad on ConsultaTarifa__c (before insert, before update, before delete, after undelete) {
    P05TarifasServicio.validarIntegridad();
}
