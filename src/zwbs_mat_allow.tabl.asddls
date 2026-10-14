@EndUserText.label : 'Allowed Materials for WBS Elements'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table zwbs_mat_allow {

  key mandt      : mandt not null;
  key ps_psp_pnr : ps_psp_pnr not null;
  key matnr      : matnr not null;
  key werks      : werks_d not null;
  posid          : ps_posid;
  allow_flag     : xfeld;
  valid_from     : dats;
  valid_to       : dats;
  @Semantics.quantity.unitOfMeasure : 'zwbs_mat_allow.meins'
  max_quantity   : menge_d;
  meins          : meins;
  remarks        : char100;
  ernam          : ernam;
  erdat          : erdat;
  erzet          : erzet;
  aenam          : aenam;
  aedat          : aedat;
  aezet          : aezet;

}
