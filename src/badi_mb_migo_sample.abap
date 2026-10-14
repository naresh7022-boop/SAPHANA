*&---------------------------------------------------------------------*
*& Sample BAdI Implementation: MB_MIGO_BADI
*& Method: LINE_MODIFY (or CHECK_ITEM)
*& Purpose: Enforce that only allowed materials can be consumed against
*&          a WBS Element (Movement Type 221 / 281)
*&---------------------------------------------------------------------*
METHOD if_ex_mb_migo_badi~line_modify.

  DATA: lv_allowed TYPE abap_bool,
        lv_message TYPE string,
        ls_entry   TYPE zwbs_mat_allow.

  " Check if line has WBS element assigned (e.g. Movement Type 221 - GI for Project)
  IF cs_goitem-matnr IS NOT INITIAL AND cs_goitem-ps_psp_pnr IS NOT INITIAL.

    zcl_ps_wbs_mat_validate=>check_material_allowed(
      EXPORTING
        iv_wbs      = cs_goitem-ps_psp_pnr
        iv_matnr    = cs_goitem-matnr
        iv_werks    = cs_goitem-werks
        iv_quantity = cs_goitem-erfmg
        iv_date     = cs_goitem-bldat
      IMPORTING
        ev_allowed  = lv_allowed
        ev_message  = lv_message
        es_entry    = ls_entry
    ).

    IF lv_allowed = abap_false.
      MESSAGE lv_message TYPE 'E'.
    ENDIF.

  ENDIF.

ENDMETHOD.
