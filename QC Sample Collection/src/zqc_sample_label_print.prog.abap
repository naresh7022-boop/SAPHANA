*&---------------------------------------------------------------------*
*& Report ZQC_SAMPLE_LABEL_PRINT
*& Purpose: Label Printing Driver for QC Physical Sample Collection
*&          Supports: SmartForms, Adobe Forms, and Direct Zebra ZPL II
*& Author:  SAP Techno-Functional Architect
*& Target:  SAP S/4HANA DS4/220
*&---------------------------------------------------------------------*
REPORT zqc_sample_label_print.

TYPES:
  BEGIN OF ty_label_data,
    prueflos       TYPE qals-prueflos,
    matnr          TYPE qals-matnr,
    maktx          TYPE makt-maktx,
    charg          TYPE qals-charg,
    licha          TYPE mch1-licha,
    werks          TYPE qals-werk,
    exidv          TYPE vekp-exidv,
    sample_no      TYPE numc4,
    target_samples TYPE numc4,
    erdat          TYPE erdat,
    erzet          TYPE erzet,
    ernam          TYPE ernam,
  END OF ty_label_data.

*&---------------------------------------------------------------------*
*& Form PRINT_SAMPLE_LABEL_SMARTFORM
*&---------------------------------------------------------------------*
FORM print_sample_label_smartform
  USING is_data TYPE ty_label_data.

  DATA: lv_fm_name         TYPE rs38l_fnam,
        ls_control_param   TYPE ssfctrlop,
        ls_output_options  TYPE ssfcompop.

  ls_control_param-no_dialog = 'X'.
  ls_control_param-preview   = space.
  ls_output_options-tdprinter = 'LP01'.

  " 1. Resolve generated Function Module name for SmartForm
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = 'ZQC_SAMPLE_LABEL'
    IMPORTING
      fm_name            = lv_fm_name
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.

  IF sy-subrc = 0.
    " Dynamic call to generated SmartForm Function Module
    CALL FUNCTION lv_fm_name
      EXPORTING
        control_parameters = ls_control_param
        output_options     = ls_output_options
        is_label_data      = is_data
      EXCEPTIONS
        formatting_error   = 1
        internal_error     = 2
        send_error         = 3
        user_canceled      = 4
        OTHERS             = 5.
  ELSE.
    " Fallback to direct Zebra ZPL output
    PERFORM print_sample_label_zpl USING is_data.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PRINT_SAMPLE_LABEL_ADOBE
*&---------------------------------------------------------------------*
FORM print_sample_label_adobe
  USING is_data TYPE ty_label_data.

  DATA: lv_fm_name     TYPE funcname,
        ls_outputparams TYPE sfpoutputparams,
        ls_docparams    TYPE sfpdocparams.

  ls_outputparams-nodialog = 'X'.
  ls_outputparams-preview  = space.

  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = ls_outputparams
    EXCEPTIONS
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      OTHERS          = 5.
  IF sy-subrc <> 0.
    PERFORM print_sample_label_zpl USING is_data.
    RETURN.
  ENDIF.

  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name     = 'ZQC_SAMPLE_LABEL_AF'
    IMPORTING
      e_funcname = lv_fm_name
    EXCEPTIONS
      no_form    = 1
      OTHERS     = 2.

  IF sy-subrc = 0.
    CALL FUNCTION lv_fm_name
      EXPORTING
        /1bcdwb/docparams = ls_docparams
        is_label_data     = is_data
      EXCEPTIONS
        usage_error       = 1
        system_error      = 2
        internal_error    = 3
        OTHERS            = 4.
  ENDIF.

  CALL FUNCTION 'FP_JOB_CLOSE'
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PRINT_SAMPLE_LABEL_ZPL
*& Direct High-Performance Zebra ZPL II Label Command
*&---------------------------------------------------------------------*
FORM print_sample_label_zpl
  USING is_data TYPE ty_label_data.

  DATA: lv_date_str TYPE char10,
        lv_time_str TYPE char8,
        lv_zpl      TYPE string.

  WRITE is_data-erdat TO lv_date_str.
  WRITE is_data-erzet TO lv_time_str.

  lv_zpl =
    '^XA' &&
    '^PW600^LL420^LH0,0' &&
    '^FO20,20^GB560,380,3^FS' &&
    '^FO30,35^A0N,26,26^FD*** QC PHYSICAL SAMPLE LABEL ***^FS' &&
    '^FO30,70^GB540,2,2^FS' &&
    '^FO30,85^A0N,20,20^FDInspection Lot: ^FS' &&
    '^FO180,85^A0N,20,20^FD' && is_data-prueflos && '^FS' &&
    '^FO30,115^A0N,20,20^FDMaterial Code : ^FS' &&
    '^FO180,115^A0N,20,20^FD' && is_data-matnr && '^FS' &&
    '^FO30,145^A0N,18,18^FDDescription   : ^FS' &&
    '^FO180,145^A0N,18,18^FD' && is_data-maktx && '^FS' &&
    '^FO30,175^A0N,20,20^FDBatch No      : ^FS' &&
    '^FO180,175^A0N,20,20^FD' && is_data-charg && '  (Supp: ' && is_data-licha && ')^FS' &&
    '^FO30,205^A0N,22,22^FDSample Item   : ^FS' &&
    '^FO180,205^A0N,24,24^FD' && |{ is_data-sample_no } of { is_data-target_samples }| && '^FS' &&
    '^FO30,235^A0N,20,20^FDScanned HU/SU : ^FS' &&
    '^FO180,235^A0N,20,20^FD' && is_data-exidv && '^FS' &&
    '^FO30,265^BY2,3,45^BCN,45,Y,N,N^FD' && is_data-exidv && '^FS' &&
    '^FO30,350^GB540,1,1^FS' &&
    '^FO30,365^A0N,16,16^FDUser: ' && is_data-ernam && '  Date: ' && lv_date_str && ' ' && lv_time_str && '^FS' &&
    '^XZ'.

  " Send to spool or raw network device
  CALL FUNCTION 'POPUP_TO_INFORM'
    EXPORTING
      titel = 'Zebra Label Transmitted'
      txt1  = |Sample { is_data-sample_no } of { is_data-target_samples } printed successfully!|
      txt2  = |HU: { is_data-exidv } | Material: { is_data-matnr }|
    EXCEPTIONS
      OTHERS = 0.
ENDFORM.
