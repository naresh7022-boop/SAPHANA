*&---------------------------------------------------------------------*
*& Table: ZQC_SAMPLE_LOG
*& Description: Quality Control (QC) Physical Sample Collection Audit Log
*& Delivery Class: A (Application Table)
*& Data Browser/Table View Maint.: Allowed
*&---------------------------------------------------------------------*
* Fields Definition:
* MANDT          TYPE mandt         Key   Client
* PRUEFLOS       TYPE qals-prueflos Key   Inspection Lot Number
* EXIDV          TYPE vekp-exidv    Key   Scanned Handling Unit / Storage Unit
* SAMPLE_NO      TYPE numc4               Sequential Sample Number (e.g. 0001, 0002..)
* TARGET_SAMPLES TYPE numc4               Calculated Target Samples (ceil(sqrt(N) + 1))
* TOTAL_BAGS     TYPE i                   Total Bags/Drums (N)
* MATNR          TYPE qals-matnr          Material Number
* MAKTX          TYPE makt-maktx          Material Description
* CHARG          TYPE qals-charg          Batch Number
* LICHA          TYPE mch1-licha          Supplier Batch Number
* WERKS          TYPE qals-werk           Plant
* LOSMENGE       TYPE qals-losmenge       Received Quantity
* MEINS          TYPE meins               Base Unit of Measure
* ERDAT          TYPE erdat               Collection Date
* ERZET          TYPE erzet               Collection Time
* ERNAM          TYPE ernam               Collector User ID (SY-UNAME)
* STATUS         TYPE char20              Collection Status (e.g. COLLECTED, PRINTED)
* LABEL_PRINTED  TYPE char1               Label Print Flag ('X' = Yes)
*&---------------------------------------------------------------------*
@EndUserText.label : 'QC Physical Sample Collection Audit Log'
@AbapCatalog.enhancementCategory : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table zqc_sample_log {
  key mandt          : mandt not null;
  key prueflos       : prueflos not null;
  key exidv          : exidv not null;
  sample_no          : numc4;
  target_samples     : numc4;
  total_bags         : abap.int4;
  matnr              : matnr;
  maktx              : maktx;
  charg              : charg_d;
  licha              : licha;
  werks              : werks_d;
  losmenge           : losmenge;
  meins              : meins;
  erdat              : erdat;
  erzet              : erzet;
  ernam              : ernam;
  status             : abap.char(20);
  label_printed      : abap.char(1);
}
