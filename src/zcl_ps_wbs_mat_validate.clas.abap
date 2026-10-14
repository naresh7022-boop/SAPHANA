CLASS zcl_ps_wbs_mat_validate DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    TYPES:
      BEGIN OF ty_result,
        is_allowed   TYPE abap_bool,
        message      TYPE string,
        ps_psp_pnr   TYPE ps_psp_pnr,
        posid        TYPE ps_posid,
        matnr        TYPE matnr,
        werks        TYPE werks_d,
        max_quantity TYPE menge_d,
        meins        TYPE meins,
      END OF ty_result .

    CLASS-METHODS check_material_allowed
      IMPORTING
        !iv_wbs        TYPE any
        !iv_matnr      TYPE any
        !iv_werks      TYPE werks_d OPTIONAL
        !iv_quantity   TYPE menge_d OPTIONAL
        !iv_date       TYPE dats DEFAULT sy-datum
      EXPORTING
        !ev_allowed    TYPE abap_bool
        !ev_message    TYPE string
        !es_entry      TYPE zwbs_mat_allow
      RETURNING
        VALUE(rs_info) TYPE ty_result .

    CLASS-METHODS add_allowed_material
      IMPORTING
        !iv_wbs          TYPE any
        !iv_matnr        TYPE any
        !iv_werks        TYPE werks_d OPTIONAL
        !iv_allow_flag   TYPE xfeld DEFAULT 'X'
        !iv_valid_from   TYPE dats DEFAULT sy-datum
        !iv_valid_to     TYPE dats DEFAULT '99991231'
        !iv_max_quantity TYPE menge_d OPTIONAL
        !iv_meins        TYPE meins OPTIONAL
        !iv_remarks      TYPE char100 OPTIONAL
      EXPORTING
        !ev_success      TYPE abap_bool
        !ev_message      TYPE string
        !es_entry        TYPE zwbs_mat_allow .

    CLASS-METHODS delete_allowed_material
      IMPORTING
        !iv_wbs     TYPE any
        !iv_matnr   TYPE any
        !iv_werks   TYPE werks_d OPTIONAL
      EXPORTING
        !ev_success TYPE abap_bool
        !ev_message TYPE string .

    CLASS-METHODS convert_wbs_to_internal
      IMPORTING
        !iv_wbs              TYPE any
      RETURNING
        VALUE(rv_ps_psp_pnr) TYPE ps_psp_pnr .

    CLASS-METHODS convert_wbs_to_external
      IMPORTING
        !iv_ps_psp_pnr  TYPE ps_psp_pnr
      RETURNING
        VALUE(rv_posid) TYPE ps_posid .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_ps_wbs_mat_validate IMPLEMENTATION.

  METHOD convert_wbs_to_internal.
    DATA: lv_input TYPE string,
          lv_posnr TYPE ps_posnr.

    CLEAR rv_ps_psp_pnr.
    IF iv_wbs IS INITIAL.
      RETURN.
    ENDIF.

    lv_input = iv_wbs.
    CONDENSE lv_input.

    IF lv_input CO '0123456789' AND strlen( lv_input ) <= 8.
      CALL FUNCTION 'CONVERSION_EXIT_ABPSP_INPUT'
        EXPORTING
          input  = lv_input
        IMPORTING
          output = lv_posnr
        EXCEPTIONS
          OTHERS = 1.
      IF sy-subrc = 0.
        rv_ps_psp_pnr = lv_posnr.
        RETURN.
      ENDIF.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_ABPSP_INPUT'
      EXPORTING
        input  = lv_input
      IMPORTING
        output = lv_posnr
      EXCEPTIONS
        OTHERS = 1.

    IF sy-subrc = 0 AND lv_posnr IS NOT INITIAL.
      rv_ps_psp_pnr = lv_posnr.
    ELSE.
      SELECT SINGLE pspnr FROM prps INTO rv_ps_psp_pnr
        WHERE posid = lv_input.
    ENDIF.
  ENDMETHOD.

  METHOD convert_wbs_to_external.
    DATA: lv_posid TYPE ps_posid.
    CLEAR rv_posid.
    IF iv_ps_psp_pnr IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE posid FROM prps INTO lv_posid
      WHERE pspnr = iv_ps_psp_pnr.
    IF sy-subrc = 0.
      rv_posid = lv_posid.
    ELSE.
      CALL FUNCTION 'CONVERSION_EXIT_ABPSP_OUTPUT'
        EXPORTING
          input  = iv_ps_psp_pnr
        IMPORTING
          output = rv_posid
        EXCEPTIONS
          OTHERS = 1.
    ENDIF.
  ENDMETHOD.

  METHOD add_allowed_material.
    DATA: lv_ps_psp_pnr TYPE ps_psp_pnr,
          lv_posid      TYPE ps_posid,
          lv_matnr      TYPE matnr,
          lv_mat_input  TYPE string,
          ls_entry_db   TYPE zwbs_mat_allow,
          lv_meins      TYPE meins.

    CLEAR: ev_success, ev_message, es_entry.
    ev_success = abap_false.

    " 1. Resolve and Validate WBS Element
    lv_ps_psp_pnr = convert_wbs_to_internal( iv_wbs ).
    IF lv_ps_psp_pnr IS INITIAL.
      ev_message = |WBS Element '{ iv_wbs }' not found in PRPS.|.
      RETURN.
    ENDIF.
    lv_posid = convert_wbs_to_external( lv_ps_psp_pnr ).

    " 2. Format and Validate Material Number
    lv_mat_input = iv_matnr.
    CONDENSE lv_mat_input.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input        = lv_mat_input
      IMPORTING
        output       = lv_matnr
      EXCEPTIONS
        length_error = 1
        OTHERS       = 2.
    IF sy-subrc <> 0 OR lv_matnr IS INITIAL.
      lv_matnr = iv_matnr.
    ENDIF.

    SELECT SINGLE meins FROM mara INTO lv_meins
      WHERE matnr = lv_matnr.
    IF sy-subrc <> 0.
      ev_message = |Material '{ lv_matnr ALPHA = OUT }' not found in MARA master.|.
      RETURN.
    ENDIF.

    IF iv_meins IS NOT INITIAL.
      lv_meins = iv_meins.
    ENDIF.

    " 3. Build Record
    es_entry-mandt        = sy-mandt.
    es_entry-ps_psp_pnr   = lv_ps_psp_pnr.
    es_entry-matnr        = lv_matnr.
    es_entry-werks        = iv_werks.
    es_entry-posid        = lv_posid.
    es_entry-allow_flag   = COND #( WHEN iv_allow_flag IS NOT INITIAL THEN iv_allow_flag ELSE 'X' ).
    es_entry-valid_from   = COND #( WHEN iv_valid_from IS NOT INITIAL THEN iv_valid_from ELSE sy-datum ).
    es_entry-valid_to     = COND #( WHEN iv_valid_to IS NOT INITIAL THEN iv_valid_to ELSE '99991231' ).
    es_entry-max_quantity = iv_max_quantity.
    es_entry-meins        = lv_meins.
    es_entry-remarks      = iv_remarks.

    " Check if entry already exists (Audit info preservation)
    SELECT SINGLE * FROM zwbs_mat_allow INTO ls_entry_db
      WHERE ps_psp_pnr = lv_ps_psp_pnr
        AND matnr      = lv_matnr
        AND werks      = iv_werks.
    IF sy-subrc = 0.
      es_entry-ernam = ls_entry_db-ernam.
      es_entry-erdat = ls_entry_db-erdat.
      es_entry-erzet = ls_entry_db-erzet.
      es_entry-aenam = sy-uname.
      es_entry-aedat = sy-datum.
      es_entry-aezet = sy-uzeit.
    ELSE.
      es_entry-ernam = sy-uname.
      es_entry-erdat = sy-datum.
      es_entry-erzet = sy-uzeit.
    ENDIF.

    MODIFY zwbs_mat_allow FROM es_entry.
    IF sy-subrc = 0.
      COMMIT WORK.
      ev_success = abap_true.
      ev_message = |Material { lv_matnr ALPHA = OUT } successfully added/updated for WBS { lv_posid }.|.
    ELSE.
      ROLLBACK WORK.
      ev_message = |Database insert failed for WBS { lv_posid } and Material { lv_matnr ALPHA = OUT }.|.
    ENDIF.
  ENDMETHOD.

  METHOD delete_allowed_material.
    DATA: lv_ps_psp_pnr TYPE ps_psp_pnr,
          lv_matnr      TYPE matnr,
          lv_mat_input  TYPE string.

    CLEAR: ev_success, ev_message.
    ev_success = abap_false.

    lv_ps_psp_pnr = convert_wbs_to_internal( iv_wbs ).
    IF lv_ps_psp_pnr IS INITIAL.
      ev_message = |WBS Element '{ iv_wbs }' not found in PRPS.|.
      RETURN.
    ENDIF.

    lv_mat_input = iv_matnr.
    CONDENSE lv_mat_input.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input        = lv_mat_input
      IMPORTING
        output       = lv_matnr
      EXCEPTIONS
        length_error = 1
        OTHERS       = 2.
    IF sy-subrc <> 0 OR lv_matnr IS INITIAL.
      lv_matnr = iv_matnr.
    ENDIF.

    DELETE FROM zwbs_mat_allow
      WHERE ps_psp_pnr = lv_ps_psp_pnr
        AND matnr      = lv_matnr
        AND werks      = iv_werks.

    IF sy-subrc = 0.
      COMMIT WORK.
      ev_success = abap_true.
      ev_message = |Record deleted successfully for WBS { iv_wbs } and Material { lv_matnr ALPHA = OUT }.|.
    ELSE.
      ev_message = |Record not found to delete.|.
    ENDIF.
  ENDMETHOD.

  METHOD check_material_allowed.
    DATA: lv_ps_psp_pnr TYPE ps_psp_pnr,
          lv_matnr      TYPE matnr,
          lv_posid      TYPE ps_posid,
          ls_allow      TYPE zwbs_mat_allow,
          lv_mat_input  TYPE string.

    CLEAR: ev_allowed, ev_message, es_entry, rs_info.
    ev_allowed = abap_false.

    lv_ps_psp_pnr = convert_wbs_to_internal( iv_wbs ).
    IF lv_ps_psp_pnr IS INITIAL.
      ev_message = |WBS Element '{ iv_wbs }' is invalid or does not exist in PRPS.|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      RETURN.
    ENDIF.
    lv_posid = convert_wbs_to_external( lv_ps_psp_pnr ).

    lv_mat_input = iv_matnr.
    CONDENSE lv_mat_input.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input        = lv_mat_input
      IMPORTING
        output       = lv_matnr
      EXCEPTIONS
        length_error = 1
        OTHERS       = 2.
    IF sy-subrc <> 0 OR lv_matnr IS INITIAL.
      lv_matnr = iv_matnr.
    ENDIF.

    IF iv_werks IS NOT INITIAL.
      SELECT SINGLE * FROM zwbs_mat_allow INTO ls_allow
        WHERE ps_psp_pnr = lv_ps_psp_pnr
          AND matnr      = lv_matnr
          AND werks      = iv_werks.
    ENDIF.

    IF ls_allow IS INITIAL.
      SELECT SINGLE * FROM zwbs_mat_allow INTO ls_allow
        WHERE ps_psp_pnr = lv_ps_psp_pnr
          AND matnr      = lv_matnr
          AND werks      = space.
    ENDIF.

    IF ls_allow IS INITIAL.
      ev_allowed = abap_false.
      ev_message = |Material { lv_matnr ALPHA = OUT } is NOT allowed for WBS Element { lv_posid }.|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      rs_info-ps_psp_pnr = lv_ps_psp_pnr.
      rs_info-posid      = lv_posid.
      rs_info-matnr      = lv_matnr.
      rs_info-werks      = iv_werks.
      RETURN.
    ENDIF.

    IF ls_allow-allow_flag <> 'X'.
      ev_allowed = abap_false.
      ev_message = |Material { lv_matnr ALPHA = OUT } is blocked/inactive for WBS { lv_posid }.|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      RETURN.
    ENDIF.

    IF ls_allow-valid_from IS NOT INITIAL AND iv_date < ls_allow-valid_from.
      ev_allowed = abap_false.
      ev_message = |Material { lv_matnr ALPHA = OUT } is not yet valid for WBS { lv_posid } (Valid from: { ls_allow-valid_from DATE = USER }).|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      RETURN.
    ENDIF.

    IF ls_allow-valid_to IS NOT INITIAL AND iv_date > ls_allow-valid_to.
      ev_allowed = abap_false.
      ev_message = |Material { lv_matnr ALPHA = OUT } validity expired for WBS { lv_posid } (Valid to: { ls_allow-valid_to DATE = USER }).|.
      rs_info-is_allowed = abap_false.
      rs_info-message    = ev_message.
      RETURN.
    ENDIF.

    IF ls_allow-max_quantity > 0 AND iv_quantity > 0.
      IF iv_quantity > ls_allow-max_quantity.
        ev_allowed = abap_false.
        ev_message = |Quantity { iv_quantity } exceeds max allowed limit ({ ls_allow-max_quantity } { ls_allow-meins }) for WBS { lv_posid }.|.
        rs_info-is_allowed = abap_false.
        rs_info-message    = ev_message.
        RETURN.
      ENDIF.
    ENDIF.

    ev_allowed = abap_true.
    ev_message = |Material { lv_matnr ALPHA = OUT } is allowed for WBS Element { lv_posid }.|.
    es_entry   = ls_allow.

    rs_info-is_allowed   = abap_true.
    rs_info-message      = ev_message.
    rs_info-ps_psp_pnr   = lv_ps_psp_pnr.
    rs_info-posid        = lv_posid.
    rs_info-matnr        = lv_matnr.
    rs_info-werks        = ls_allow-werks.
    rs_info-max_quantity = ls_allow-max_quantity.
    rs_info-meins        = ls_allow-meins.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    DATA: lv_ok  TYPE abap_bool,
          lv_msg TYPE string,
          ls_ent TYPE zwbs_mat_allow.

    out->write( '=== Testing ZCL_PS_WBS_MAT_VALIDATE on SAP Client 220 ===' ).

    " 1. Add material using add_allowed_material
    add_allowed_material(
      EXPORTING
        iv_wbs          = '8203-IT1'
        iv_matnr        = '8000009756'
        iv_werks        = '1120'
        iv_max_quantity = 250
        iv_remarks      = 'Approved for IT Purchases'
      IMPORTING
        ev_success      = lv_ok
        ev_message      = lv_msg
        es_entry        = ls_ent
    ).
    out->write( |[Add Material]: Success={ lv_ok } - { lv_msg }| ).

    " 2. Validate allowed material
    check_material_allowed(
      EXPORTING
        iv_wbs      = '8203-IT1'
        iv_matnr    = '8000009756'
        iv_werks    = '1120'
        iv_quantity = 50
      IMPORTING
        ev_allowed  = lv_ok
        ev_message  = lv_msg
    ).
    out->write( |[Check Material]: Allowed={ lv_ok } - { lv_msg }| ).

    out->write( '=== Test Finished ===' ).
  ENDMETHOD.

ENDCLASS.
