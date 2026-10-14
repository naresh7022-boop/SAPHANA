*&---------------------------------------------------------------------*
*& Sample BAdI Implementation: ME_PROCESS_REQ_CUST
*& Method: PROCESS_ITEM (or CHECK)
*& Purpose: Enforce that only allowed materials can be purchased against
*&          a WBS Element (Account Assignment Category 'P')
*&---------------------------------------------------------------------*
METHOD if_ex_me_process_req_cust~process_item.

  DATA: ls_item     TYPE mereq_item,
        lt_account  TYPE mmpur_account_list,
        ls_account  TYPE mereq_account,
        lv_allowed  TYPE abap_bool,
        lv_message  TYPE string,
        ls_entry    TYPE zwbs_mat_allow.

  " 1. Retrieve PR item data
  ls_item = im_item->get_data( ).

  " 2. Only check if Account Assignment Category is 'P' (Project / WBS)
  CHECK ls_item-knttp = 'P' AND ls_item-matnr IS NOT INITIAL.

  " 3. Get Account Assignment details for WBS Element
  lt_account = im_item->get_accountings( ).
  LOOP AT lt_account INTO DATA(lo_account).
    ls_account = lo_account-accounting->get_data( ).
    IF ls_account-ps_psp_pnr IS NOT INITIAL.

      " 4. Call Central Validation Engine
      zcl_ps_wbs_mat_validate=>check_material_allowed(
        EXPORTING
          iv_wbs      = ls_account-ps_psp_pnr
          iv_matnr    = ls_item-matnr
          iv_werks    = ls_item-werks
          iv_quantity = ls_item-menge
          iv_date     = ls_item-badat
        IMPORTING
          ev_allowed  = lv_allowed
          ev_message  = lv_message
          es_entry    = ls_entry
      ).

      " 5. If disallowed, raise error message on PR item
      IF lv_allowed = abap_false.
        im_item->invalidate( ).
        mmpur_message_forced 'E' '00' '001' lv_message '' '' ''.
      ENDIF.

    ENDIF.
  ENDLOOP.

ENDMETHOD.
